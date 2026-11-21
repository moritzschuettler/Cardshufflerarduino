/*
 * ===========================================================================
 *  Arduino Poker-Kartenmischer  (2-Schacht "Riffle"-Mischer)
 * ===========================================================================
 *
 *  Prinzip:
 *    - Das Deck wird grob halbiert und in den linken und rechten Schacht gelegt.
 *    - Unter jedem Schacht sitzt ein N20-Getriebemotor mit Gummi-Reibrad, das
 *      immer die UNTERSTE Karte durch einen schmalen Spalt (Gate) schiebt.
 *    - Die Karte kippt über die Kante und fällt in das mittlere Ausgabefach.
 *    - Eine IR-Lichtschranke quer durch das Ausgabefach erkennt jede fallende
 *      Karte (egal von welcher Seite). Sobald die Karte erkannt wurde, wird
 *      der Motor gebremst. Kommt nach Timeout keine Karte -> Schacht leer.
 *    - Welche Seite als Nächstes eine Karte abgibt, wird nach dem Gilbert-
 *      Shannon-Reeds-Modell (mathematisches Modell eines echten Riffle-
 *      Shuffles) zufällig bestimmt:  P(links) = Karten_links / Karten_gesamt.
 *
 *  Hardware (siehe README.md):
 *    Arduino Nano / Uno, TB6612FNG Motortreiber, 2x N20-Motor 6V,
 *    1x IR-Lichtschranke 5 mm (Sender + Empfänger), 1x Taster, 1x LED,
 *    optional: passiver Buzzer.
 *
 *  Bedienung:
 *    - Taster kurz drücken      -> Mischen starten (ein Durchgang)
 *    - Taster während Mischen   -> Abbruch
 *    - Taster lang (>2 s)       -> Zähler der Durchgänge zurücksetzen
 *    - Serieller Monitor 115200 Baud, Befehle:
 *        s = Mischen starten        l = 1 Karte links   r = 1 Karte rechts
 *        t = Sensortest (5 s)       m = Motortest       h = Hilfe
 *
 *  Empfehlung: 3–4 Durchgänge (Karten aus dem Ausgabefach wieder teilen und
 *  neu einlegen). Mathematisch gelten ~7 Riffle-Shuffles als "voll gemischt"
 *  (Bayer & Diaconis); 4 Maschinen-Durchgänge + 1x Abheben sind für
 *  Heimspiele mehr als ausreichend.
 * ===========================================================================
 */

// ------------------------------- PINS ---------------------------------------
// TB6612FNG
const uint8_t PIN_STBY  = 4;
const uint8_t PIN_PWMA  = 5;   // Motor A = LINKS  (PWM-Pin!)
const uint8_t PIN_AIN1  = 7;
const uint8_t PIN_AIN2  = 8;
const uint8_t PIN_PWMB  = 6;   // Motor B = RECHTS (PWM-Pin!)
const uint8_t PIN_BIN1  = 9;
const uint8_t PIN_BIN2  = 10;

// Sensoren / Bedienung
const uint8_t PIN_SENSOR = 2;  // IR-Lichtschranke Empfänger (Signal)
const uint8_t PIN_BUTTON = 12; // Taster gegen GND (interner Pull-up)
const uint8_t PIN_LED    = 13; // Status-LED (onboard LED reicht)
const uint8_t PIN_BUZZER = 11; // optionaler passiver Buzzer (sonst frei lassen)
const uint8_t PIN_NOISE  = A0; // UNBESCHALTET lassen -> Zufalls-Seed

// ----------------------------- EINSTELLUNGEN --------------------------------
const uint8_t  DECK_SIZE          = 52;    // Karten im Deck (ggf. +Joker)
const uint8_t  FEED_SPEED         = 170;   // PWM 0..255 Vorschub-Geschwindigkeit
const uint8_t  KICK_SPEED         = 255;   // PWM für Anlauf-Kick
const uint16_t KICK_MS            = 25;    // Dauer Anlauf-Kick
const uint16_t FEED_TIMEOUT_MS    = 1200;  // so lange max. auf eine Karte warten
const uint16_t PASS_TIMEOUT_MS    = 600;   // max. Zeit, bis Karte Sensor verlassen hat
const uint16_t AFTER_CARD_RUN_MS  = 0;     // Motor nach Erkennung noch kurz weiterlaufen
const uint16_t SETTLE_MS          = 60;    // Pause zwischen zwei Karten
const uint8_t  FEED_RETRIES       = 2;     // Wiederholungen (mit kurzem Rückwärts-Ruck)
const uint16_t WIGGLE_MS          = 70;    // Dauer Rückwärts-Ruck
const uint8_t  MAX_SAME_SIDE      = 5;     // max. Karten am Stück von einer Seite (0 = aus)

// Sensor-Logik: Lichtschranken-Empfänger (Open-Collector, interner Pull-up)
// liefern LOW, wenn der Strahl UNTERBROCHEN ist (= Karte).
// Falls dein Modul umgekehrt arbeitet -> HIGH eintragen.
const uint8_t  SENSOR_ACTIVE      = LOW;
const uint8_t  SENSOR_DEBOUNCE    = 3;     // so viele gleiche Lesungen (~0,2 ms Abstand)

// Motor-Drehrichtung umkehren, falls ein Motor "falsch herum" läuft
const bool     INVERT_LEFT        = false;
const bool     INVERT_RIGHT       = false;

const uint16_t LONG_PRESS_MS      = 2000;

// ------------------------------- TYPEN --------------------------------------
enum Side : uint8_t { LEFT = 0, RIGHT = 1 };
enum FeedResult : uint8_t { FEED_OK, FEED_EMPTY, FEED_JAM, FEED_ABORT };

struct Tray {
  uint8_t  motorPwm, in1, in2;
  bool     invert;
  bool     empty;
  int16_t  estimate;   // geschätzte Restkarten (für Wahrscheinlichkeit)
  uint8_t  fed;        // tatsächlich ausgegebene Karten
};

Tray trays[2] = {
  { PIN_PWMA, PIN_AIN1, PIN_AIN2, INVERT_LEFT,  false, 0, 0 },
  { PIN_PWMB, PIN_BIN1, PIN_BIN2, INVERT_RIGHT, false, 0, 0 },
};

uint8_t passCount = 0;
volatile bool abortRequested = false;

// --------------------------- HILFSFUNKTIONEN --------------------------------
void beep(uint16_t freq, uint16_t ms) {
  tone(PIN_BUZZER, freq, ms);
  delay(ms + 10);
}

void blink(uint8_t times, uint16_t onMs = 150, uint16_t offMs = 150) {
  for (uint8_t i = 0; i < times; i++) {
    digitalWrite(PIN_LED, HIGH); delay(onMs);
    digitalWrite(PIN_LED, LOW);  delay(offMs);
  }
}

bool buttonPressed() {
  return digitalRead(PIN_BUTTON) == LOW;
}

// Prüft während laufender Vorgänge, ob abgebrochen werden soll
bool checkAbort() {
  if (buttonPressed()) abortRequested = true;
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 'x' || c == 's') abortRequested = true;
  }
  return abortRequested;
}

// Entprellte Sensorabfrage: true = Karte unterbricht die Lichtschranke
bool cardDetected() {
  for (uint8_t i = 0; i < SENSOR_DEBOUNCE; i++) {
    if (digitalRead(PIN_SENSOR) != SENSOR_ACTIVE) return false;
    delayMicroseconds(200);
  }
  return true;
}

bool sensorClear() {
  for (uint8_t i = 0; i < SENSOR_DEBOUNCE; i++) {
    if (digitalRead(PIN_SENSOR) == SENSOR_ACTIVE) return false;
    delayMicroseconds(200);
  }
  return true;
}

// ----------------------------- MOTOREN --------------------------------------
// speed > 0 = vorwärts (Karte raus), speed < 0 = rückwärts
void motorRun(Tray &t, int16_t speed) {
  bool fwd = speed >= 0;
  if (t.invert) fwd = !fwd;
  digitalWrite(t.in1, fwd ? HIGH : LOW);
  digitalWrite(t.in2, fwd ? LOW : HIGH);
  analogWrite(t.motorPwm, constrain(abs(speed), 0, 255));
}

void motorBrake(Tray &t) {
  // Kurzschlussbremse: Rad stoppt sofort -> keine zweite Karte rutscht nach
  digitalWrite(t.in1, HIGH);
  digitalWrite(t.in2, HIGH);
  analogWrite(t.motorPwm, 255);
}

void motorsOff() {
  for (uint8_t i = 0; i < 2; i++) {
    digitalWrite(trays[i].in1, LOW);
    digitalWrite(trays[i].in2, LOW);
    analogWrite(trays[i].motorPwm, 0);
  }
}

// ------------------------- EINE KARTE AUSGEBEN ------------------------------
FeedResult feedOneCard(Tray &t) {
  for (uint8_t attempt = 0; attempt <= FEED_RETRIES; attempt++) {

    // Falls noch eine Karte im Sensor hängt -> kurz warten
    unsigned long t0 = millis();
    while (!sensorClear()) {
      if (millis() - t0 > PASS_TIMEOUT_MS) { motorBrake(t); return FEED_JAM; }
    }

    if (attempt > 0) {           // kleiner Rückwärts-Ruck löst klemmende Karten
      motorRun(t, -FEED_SPEED);
      delay(WIGGLE_MS);
      motorBrake(t);
      delay(30);
    }

    // Anlauf-Kick, dann normale Geschwindigkeit
    motorRun(t, KICK_SPEED);
    delay(KICK_MS);
    motorRun(t, FEED_SPEED);

    // Warten, bis die Karte den Sensor erreicht (= sie fällt gerade)
    t0 = millis();
    bool seen = false;
    while (millis() - t0 < FEED_TIMEOUT_MS) {
      if (checkAbort()) { motorBrake(t); return FEED_ABORT; }
      if (cardDetected()) { seen = true; break; }
    }

    if (!seen) {                 // nichts gekommen -> nochmal probieren
      motorBrake(t);
      continue;
    }

    if (AFTER_CARD_RUN_MS) delay(AFTER_CARD_RUN_MS);
    motorBrake(t);

    // Warten, bis die Karte den Sensor wieder verlassen hat
    t0 = millis();
    while (!sensorClear()) {
      if (millis() - t0 > PASS_TIMEOUT_MS) return FEED_JAM;
    }
    delay(SETTLE_MS);
    return FEED_OK;
  }
  return FEED_EMPTY;             // nach allen Versuchen keine Karte -> leer
}

// ---------------------------- ZUFALL ----------------------------------------
void seedRandom() {
  // Rauschen vom offenen Analog-Pin + Timing-Jitter mischen
  uint32_t seed = 0;
  for (uint8_t i = 0; i < 64; i++) {
    seed = (seed << 1) ^ (seed >> 31);
    seed ^= analogRead(PIN_NOISE);
    seed ^= micros();
    delayMicroseconds(37 + (analogRead(PIN_NOISE) & 0x1F));
  }
  randomSeed(seed);
}

// ---------------------------- MISCHEN ---------------------------------------
void shufflePass() {
  abortRequested = false;
  seedRandom();                  // jedes Mal neu, Tastendruck-Zeitpunkt = Zufall

  for (uint8_t i = 0; i < 2; i++) {
    trays[i].empty    = false;
    trays[i].fed      = 0;
    trays[i].estimate = DECK_SIZE / 2;   // Annahme: grob halbiert
  }

  if (!sensorClear()) {
    Serial.println(F("!! Lichtschranke unterbrochen: Ausgabefach zu voll oder Sensor falsch ausgerichtet."));
    for (uint8_t i = 0; i < 2; i++) { beep(400, 200); delay(100); }
    blink(6, 80, 80);
    while (buttonPressed()) delay(5);
    return;
  }

  Serial.println(F("\n== Mischen gestartet =="));
  digitalWrite(PIN_LED, HIGH);
  beep(1800, 60);

  // Taster loslassen abwarten, sonst sofortiger Abbruch
  while (buttonPressed()) delay(5);
  delay(50);

  Side last = LEFT;
  uint8_t sameSideRun = 0;
  String pattern = "";

  while (!(trays[LEFT].empty && trays[RIGHT].empty)) {
    if (checkAbort()) break;

    // --- Seite wählen (Gilbert-Shannon-Reeds) ---
    Side side;
    if (trays[LEFT].empty)       side = RIGHT;
    else if (trays[RIGHT].empty) side = LEFT;
    else {
      int16_t l = max(trays[LEFT].estimate, (int16_t)1);
      int16_t r = max(trays[RIGHT].estimate, (int16_t)1);
      side = (random(l + r) < l) ? LEFT : RIGHT;

      // Begrenzung langer Serien (klebende Karten etc. vermeiden)
      if (MAX_SAME_SIDE && side == last && sameSideRun >= MAX_SAME_SIDE)
        side = (last == LEFT) ? RIGHT : LEFT;
    }

    Tray &t = trays[side];
    FeedResult res = feedOneCard(t);

    switch (res) {
      case FEED_OK:
        t.fed++;
        if (t.estimate > 1) t.estimate--;      // nie 0, solange nicht leer
        sameSideRun = (side == last) ? sameSideRun + 1 : 1;
        last = side;
        pattern += (side == LEFT) ? 'L' : 'R';
        break;

      case FEED_EMPTY:
        t.empty = true;
        Serial.print(side == LEFT ? F("Links") : F("Rechts"));
        Serial.println(F(" leer."));
        break;

      case FEED_JAM:
        motorsOff();
        Serial.print(F("!! STAU "));
        Serial.println(side == LEFT ? F("links") : F("rechts"));
        for (uint8_t i = 0; i < 3; i++) { beep(400, 250); delay(100); }
        blink(10, 80, 80);
        abortRequested = true;
        break;

      case FEED_ABORT:
        break;
    }
  }

  motorsOff();
  digitalWrite(PIN_LED, LOW);

  uint8_t total = trays[LEFT].fed + trays[RIGHT].fed;
  Serial.print(F("Reihenfolge: ")); Serial.println(pattern);
  Serial.print(F("Karten: links ")); Serial.print(trays[LEFT].fed);
  Serial.print(F(", rechts "));      Serial.print(trays[RIGHT].fed);
  Serial.print(F(", gesamt "));      Serial.println(total);

  if (abortRequested) {
    Serial.println(F("== Abgebrochen =="));
    beep(600, 300);
    while (buttonPressed()) delay(5);
    abortRequested = false;
    return;
  }

  passCount++;
  Serial.print(F("== Durchgang ")); Serial.print(passCount);
  Serial.println(F(" fertig =="));
  if (total != DECK_SIZE) {
    Serial.print(F("Hinweis: erwartet ")); Serial.print(DECK_SIZE);
    Serial.println(F(" Karten - Sensor/Gate pruefen (Doppeleinzug?)"));
  }
  beep(2000, 80); beep(2600, 120);
  delay(300);
  blink(passCount, 250, 250);    // LED blinkt Anzahl der Durchgänge
}

// ------------------------- TEST-FUNKTIONEN ----------------------------------
void sensorTest() {
  Serial.println(F("Sensortest 5 s: Karte durch die Lichtschranke fallen lassen..."));
  unsigned long t0 = millis();
  bool last = false;
  uint8_t count = 0;
  while (millis() - t0 < 5000) {
    bool now = cardDetected();
    digitalWrite(PIN_LED, now);
    if (now && !last) { count++; Serial.print(F("Karte erkannt #")); Serial.println(count); }
    last = now;
  }
  digitalWrite(PIN_LED, LOW);
  Serial.print(F("Strahl jetzt: "));
  Serial.println(cardDetected() ? F("UNTERBROCHEN (Ausrichtung pruefen!)") : F("frei - OK"));
}

void motorTest() {
  Serial.println(F("Motortest: links vor, links zurueck, rechts vor, rechts zurueck"));
  for (uint8_t i = 0; i < 2; i++) {
    Serial.println(i == LEFT ? F("Links vorwaerts") : F("Rechts vorwaerts"));
    motorRun(trays[i], FEED_SPEED); delay(800); motorBrake(trays[i]); delay(300);
    Serial.println(i == LEFT ? F("Links rueckwaerts") : F("Rechts rueckwaerts"));
    motorRun(trays[i], -FEED_SPEED); delay(800); motorBrake(trays[i]); delay(300);
  }
  motorsOff();
}

void singleCard(Side s) {
  abortRequested = false;
  FeedResult r = feedOneCard(trays[s]);
  motorsOff();
  Serial.print(s == LEFT ? F("Links: ") : F("Rechts: "));
  switch (r) {
    case FEED_OK:    Serial.println(F("Karte OK"));   break;
    case FEED_EMPTY: Serial.println(F("leer / keine Karte erkannt")); break;
    case FEED_JAM:   Serial.println(F("STAU"));       break;
    case FEED_ABORT: Serial.println(F("abgebrochen")); break;
  }
}

void printHelp() {
  Serial.println(F("\nKartenmischer - Befehle:"));
  Serial.println(F("  s  Mischen starten (x/s = Abbruch)"));
  Serial.println(F("  l  eine Karte links ausgeben"));
  Serial.println(F("  r  eine Karte rechts ausgeben"));
  Serial.println(F("  t  Sensortest (5 s)"));
  Serial.println(F("  m  Motortest"));
  Serial.println(F("  0  Durchgangszaehler zuruecksetzen"));
  Serial.println(F("  h  Hilfe"));
}

// ------------------------------ SETUP ---------------------------------------
void setup() {
  pinMode(PIN_STBY, OUTPUT);
  for (uint8_t i = 0; i < 2; i++) {
    pinMode(trays[i].motorPwm, OUTPUT);
    pinMode(trays[i].in1, OUTPUT);
    pinMode(trays[i].in2, OUTPUT);
  }
  pinMode(PIN_SENSOR, INPUT_PULLUP);
  pinMode(PIN_BUTTON, INPUT_PULLUP);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);

  motorsOff();
  digitalWrite(PIN_STBY, HIGH);        // Treiber aktivieren

  Serial.begin(115200);
  Serial.println(F("Kartenmischer bereit."));
  printHelp();

  blink(2, 80, 80);
  beep(1500, 50);
}

// ------------------------------- LOOP ---------------------------------------
void loop() {
  // --- Taster ---
  if (buttonPressed()) {
    unsigned long t0 = millis();
    while (buttonPressed() && millis() - t0 < LONG_PRESS_MS) delay(5);

    if (millis() - t0 >= LONG_PRESS_MS) {
      passCount = 0;
      Serial.println(F("Durchgangszaehler zurueckgesetzt."));
      beep(1000, 80); beep(800, 80);
      blink(3, 60, 60);
      while (buttonPressed()) delay(5);
    } else if (millis() - t0 > 30) {   // Entprellung
      shufflePass();
    }
  }

  // --- Serielle Befehle ---
  if (Serial.available()) {
    char c = Serial.read();
    switch (c) {
      case 's': shufflePass();      break;
      case 'l': singleCard(LEFT);   break;
      case 'r': singleCard(RIGHT);  break;
      case 't': sensorTest();       break;
      case 'm': motorTest();        break;
      case '0': passCount = 0; Serial.println(F("Zaehler = 0")); break;
      case 'h': printHelp();        break;
      default: break;
    }
  }

  // Ruhe-Anzeige: kurzes Aufblitzen alle 3 s
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 3000) {
    lastBlink = millis();
    digitalWrite(PIN_LED, HIGH); delay(15); digitalWrite(PIN_LED, LOW);
  }
}
