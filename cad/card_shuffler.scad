// ============================================================================
//  Arduino Poker-Kartenmischer – parametrisches CAD-Modell (OpenSCAD)
// ============================================================================
//  Öffnen mit OpenSCAD (https://openscad.org), unten bei PART das gewünschte
//  Teil wählen (oder per Kommandozeile: openscad -D 'PART="tray"' -o tray.stl)
//  und mit F6 rendern -> "Export as STL".
//
//  Teile (Anzahl in Klammern):
//    "assembly"       Gesamtansicht (nicht drucken)
//    "tray"           Kartenschacht mit Boden & Wänden          (2x)
//    "gate"           verstellbare Gate-Platte (Spalt)           (2x)
//    "motor_bracket"  Halter für N20-Getriebemotor               (2x)
//    "wheel"          Reibrad-Nabe für 2 O-Ringe                 (2x)
//    "side_box"       Unterbau links (ohne Elektronik-Ausschnitte)(1x)
//    "side_box_elec"  Unterbau rechts mit USB/Taster/Buchse       (1x)
//    "well"           mittleres Ausgabefach mit Lichtschranke    (1x)
//    "weight"         Andruckgewicht für den Kartenstapel        (2x)
//
//  Koordinaten (für das linke Modul): X = Vorschubrichtung (zur Mitte),
//  Y = Längsseite der Karte, Z = oben. Das rechte Modul ist dasselbe Teil,
//  nur um 180° gedreht.
// ============================================================================

PART = "assembly";

$fn = 64;

// ------------------------------ Karten --------------------------------------
card_w      = 63.5;   // Pokerkarte Breite (läuft in X)  – Bridge: 57
card_l      = 88.9;   // Pokerkarte Länge (Y)
clear_x     = 2.5;    // Spiel in Vorschubrichtung
clear_y     = 3.1;    // Spiel quer

// ------------------------------ Allgemein -----------------------------------
wall        = 2.4;    // Standard-Wandstärke
tol         = 0.3;    // Passungsspiel
m3_clear    = 3.4;    // Durchgangsloch M3
m3_tap      = 2.6;    // Kernloch M3 (selbstschneidend in PLA/PETG)
m3_nut_w    = 5.8;    // M3-Mutter Schlüsselweite + Spiel
m3_nut_h    = 2.6;

// ------------------------------ Schacht -------------------------------------
in_x        = card_w + clear_x;      // 66.0 Innenmaß Vorschubrichtung
in_y        = card_l + clear_y;      // 92.0 Innenmaß quer
floor_t     = 3.5;                   // Bodendicke Schacht
tray_wall_h = 30;                    // Wandhöhe über Boden
pillar      = 7;                     // Säulen für Gate-Schrauben (außen)
gate_t      = 3;                     // Dicke Gate-Platte
lip         = 4;                     // Abbruchkante hinter dem Gate
gate_gap    = 0.5;                   // Nenn-Spalt (1 Karte ≈ 0,30 mm)

tray_x      = wall + in_x + gate_t + lip;          // 75.4
tray_y      = in_y + 2*wall + 2*pillar;            // 110.8
gate_x      = wall + in_x;                         // Innenfläche Gate (68.4)
y_in0       = pillar + wall;                       // Beginn Innenraum Y

// ------------------------------ Reibrad / Motor ------------------------------
wheel_r       = 14.5;   // Außenradius MIT O-Ringen (Nabe 23 mm + 2x3 mm Schnur)
wheel_core_d  = 26;     // Nabe Ø
wheel_w       = 8;      // Breite Nabe
oring_cs      = 3;      // O-Ring Schnurstärke (O-Ring 22 x 3 NBR)
wheel_protr   = 1.0;    // so weit ragt das Rad über den Boden
wheel_setback = 12;     // Abstand Radmitte -> Gate-Innenfläche
shaft_d       = 3.0;    // N20-Welle
shaft_flat    = 2.5;    // Maß über Abflachung

n20_a         = 12.3;   // N20 Querschnitt (Breite, in X)
n20_b         = 10.3;   // N20 Querschnitt (Höhe, in Z)
bracket_len   = 18;     // Länge Motortunnel (Y)
stop_t        = 1.0;    // Anschlagwand vorn am Getriebe
hub_offset    = 1.5;    // Abstand Getriebe-Stirnfläche -> Nabe

x_w   = gate_x - wheel_setback;                    // Radmitte X
y_w   = y_in0 + in_y/2;                            // Radmitte Y (Kartenmitte)
z_w   = floor_t + wheel_protr - wheel_r;           // Radmitte Z (rel. Boden-Unterseite)
y_face= y_w - hub_offset - wheel_w/2;              // Getriebe-Stirnfläche
br_ear= 12;                                        // Schraubenabstand von Radmitte (X)

// ------------------------------ Unterbau ------------------------------------
box_h       = 40;                    // Höhe Unterbau -> Kartenboden bei 43,5 mm
box_floor   = 2;
post        = 10;                    // Eck-Säulen innen
peg_d       = 4;  peg_h = 1.8;       // Zentrierstifte

// ------------------------------ Ausgabefach ---------------------------------
well_in_x   = card_w + 4.5;          // 68
well_in_y   = card_l + 5;            // ~94
well_floor  = 3;
well_x      = well_in_x + 2*wall;    // 72.8
well_y      = tray_y;                // gleiche Breite wie Module
well_wy     = (well_y - well_in_y)/2;// dicke Längswände (Sensoren!)
lip_z       = box_h + floor_t;       // Höhe der Abbruchkante über Tisch (43.5)
well_xwall_h= lip_z - 6;             // niedrige Querwand unter der Kante
well_ywall_h= lip_z + 10;
beam_z      = 30;                    // Höhe Lichtschranke über Tisch
beam_x      = wall + 46;             // X-Position Lichtschranke (lokal)
beam_d      = 5.4;                   // Bohrung für 5-mm-IR-LED / Empfänger
notch_x     = wall + 22;  notch_w = 26;            // Griffmulde
join_z      = 12;                    // Verbindungsschrauben Höhe
join_y      = [well_wy/2, well_y - well_wy/2];

// ============================================================================
//  Hilfsmodule
// ============================================================================
module rcube(size, r=1) {                    // abgerundeter Quader (nur XY)
  hull() for (x=[r, size[0]-r], y=[r, size[1]-r])
    translate([x, y, 0]) cylinder(r=r, h=size[2]);
}

module countersink_m3(depth) {               // Senkkopf M3 von oben
  translate([0,0,-0.01]) cylinder(d=m3_clear, h=depth+0.02);
  translate([0,0,depth-1.7]) cylinder(d1=m3_clear, d2=6.4, h=1.71);
}

module nut_trap(h=m3_nut_h) {
  cylinder(d=m3_nut_w/cos(30), h=h, $fn=6);
}

// ============================================================================
//  Kartenschacht (2x drucken, Boden nach unten, keine Stützen nötig)
// ============================================================================
module tray() {
  difference() {
    union() {
      // Boden
      cube([tray_x, tray_y, floor_t]);
      // Rückwand
      translate([0, y_in0 - wall, 0]) cube([wall, in_y + 2*wall, floor_t + tray_wall_h]);
      // Seitenwände
      for (y = [y_in0 - wall, y_in0 + in_y])
        translate([0, y, 0]) cube([gate_x, wall, floor_t + tray_wall_h]);
      // Säulen für die Gate-Schrauben
      for (y = [0, tray_y - pillar])
        translate([gate_x - 8, y, 0]) cube([8, pillar, floor_t + tray_wall_h]);
      // Griff-Laschen hinten (zum Einsetzen/Herausnehmen)
    }
    // Schlitz für das Reibrad
    translate([x_w - 12, y_w - wheel_w/2 - 1.5, -1]) rcube([24, wheel_w + 3, floor_t + 2], 1.5);
    // Senkschrauben für den Motorhalter
    for (dx = [-br_ear, br_ear])
      translate([x_w + dx, y_face - bracket_len/2, 0]) countersink_m3(floor_t);
    // Kernlöcher für Gate-Schrauben (horizontal in die Säulen)
    for (y = [pillar/2, tray_y - pillar/2])
      translate([gate_x + 0.01, y, floor_t + 15]) rotate([0,-90,0]) cylinder(d=m3_tap, h=10);
    // Zentrierlöcher (Sackloch von unten) für die Stifte des Unterbaus
    for (p = peg_pos()) translate([p[0], p[1], -0.01]) cylinder(d=peg_d + tol, h=2);
    // Griffmulde in der Rückwand (Karten leichter einlegen)
    translate([-1, y_w, floor_t + tray_wall_h]) rotate([0,90,0]) cylinder(d=30, h=wall+2);
    // abgerundete Abbruchkante
    translate([tray_x, -1, floor_t]) rotate([-90,0,0]) cylinder(r=1, h=tray_y+2);
  }
}

// ============================================================================
//  Gate-Platte (2x) – flach liegend drucken! Die Unterkante bestimmt den Spalt.
// ============================================================================
gate_h = tray_wall_h;
module gate() {
  slot_c = 15 - gate_gap;   // Höhe Schlitzmitte über Gate-Unterkante
  difference() {
    cube([tray_y, gate_h, gate_t]);           // liegt flach: X=Breite, Y=Höhe
    for (x = [pillar/2, tray_y - pillar/2])
      hull() for (dy = [-2.5, 2.5])
        translate([x, slot_c + dy, -1]) cylinder(d=m3_clear, h=gate_t + 2);
    // Fase an der Oberkante (Einlegen der Karten)
    translate([-1, gate_h, gate_t]) rotate([0,90,0]) cylinder(r=1.5, h=tray_y+2, $fn=4);
  }
}

// ============================================================================
//  Motorhalter N20 (2x) – stehend drucken (Tunnel senkrecht)
// ============================================================================
module motor_bracket() {
  // Ursprung: Oberkante = Unterseite Schachtboden, Y=0 an Getriebe-Stirnfläche
  bw = n20_a + 6;
  bh = -z_w + n20_b/2 + 2.5;                 // von Boden-Unterseite bis Unterkante
  difference() {
    union() {
      translate([-bw/2, -bracket_len, -bh]) cube([bw, bracket_len + stop_t, bh]);
      // Ohren für Schrauben
      translate([-br_ear - 4, -bracket_len, -8]) cube([2*br_ear + 8, bracket_len, 8]);
    }
    // Tunnel
    translate([-n20_a/2, -bracket_len - 1, z_w - n20_b/2]) cube([n20_a, bracket_len + 1, n20_b]);
    // Wellen-/Lagerdurchbruch in der Anschlagwand
    translate([0, -1, z_w]) rotate([-90,0,0]) cylinder(d=7, h=stop_t + 2);
    // Schraubenlöcher + Mutterfallen
    for (dx = [-br_ear, br_ear]) translate([dx, -bracket_len/2, 0]) {
      translate([0,0,-9]) cylinder(d=m3_clear, h=10);
      translate([0,0,-8.01]) rotate([0,0,30]) nut_trap(3);
    }
    // Klemmschraube von unten (fixiert den Motor)
    translate([0, -bracket_len/2, -bh - 1]) cylinder(d=m3_tap, h=4);
  }
}

// ============================================================================
//  Reibrad-Nabe (2x) – für 2 O-Ringe 22 x 3 mm (NBR) oder Gummi-Streifen
// ============================================================================
module wheel() {
  groove_d = 2*wheel_r - 2*oring_cs;          // 23 mm Nutgrund
  difference() {
    cylinder(d=wheel_core_d, h=wheel_w);
    // zwei O-Ring-Nuten
    for (z = [wheel_w/4, 3*wheel_w/4])
      translate([0,0,z - (oring_cs*0.9)/2])
        difference() {
          cylinder(d=wheel_core_d + 1, h=oring_cs*0.9);
          translate([0,0,-1]) cylinder(d=groove_d, h=oring_cs + 2);
        }
    // D-Bohrung für N20-Welle (Presssitz)
    translate([0,0,-1]) intersection() {
      cylinder(d=shaft_d + 0.15, h=wheel_w + 2);
      translate([-shaft_d, -shaft_d, 0])                 // Abflachung bei x = flat - r
        cube([shaft_d + (shaft_flat - shaft_d/2) + 0.05, 2*shaft_d, wheel_w + 2]);
    }
  }
}

// ============================================================================
//  Unterbau (2x) – Kasten unter dem Schacht, mit Boden
// ============================================================================
function peg_pos() = [[post/2, post/2], [post/2, tray_y - post/2],
                      [tray_x - post/2 - 2, post/2], [tray_x - post/2 - 2, tray_y - post/2]];

module side_box(elec=false) {
  difference() {
    union() {
      difference() {
        cube([tray_x, tray_y, box_h]);
        translate([wall, wall, box_floor]) cube([tray_x - 2*wall, tray_y - 2*wall, box_h]);
      }
      // Eck-Säulen
      for (p = peg_pos()) translate([p[0] - post/2, p[1] - post/2, 0]) cube([post, post, box_h]);
      // Zentrierstifte
      for (p = peg_pos()) translate([p[0], p[1], box_h]) cylinder(d=peg_d, h=peg_h);
    }
    // Verbindung zum Ausgabefach (Stirnseite X = tray_x)
    for (y = join_y) translate([tray_x - 20, y, join_z]) rotate([0,90,0]) cylinder(d=m3_clear, h=30);
    // Kabeldurchführung zum Ausgabefach / zur anderen Seite
    translate([tray_x - wall - 1, tray_y/2 - 8, box_floor + 3]) cube([wall + 2, 16, 8]);
    // Lüftung/Gewicht sparen im Boden
    translate([tray_x/2, tray_y/2, -1]) cylinder(d=30, h=box_floor + 2);
    if (elec) {
      // Rückwand (X=0): USB-Buchse Nano + DC-Hohlbuchse 5,5x2,1
      translate([-1, 30, box_floor + 4]) cube([wall + 2, 12, 8]);       // USB Mini/USB-C
      translate([-1, 75, 20]) rotate([0,90,0]) cylinder(d=8, h=wall + 2); // DC-Buchse
      // Vorderseite (Y=0): Taster 16 mm + LED 5 mm + Schalter
      translate([tray_x/2 - 12, -1, 22]) rotate([-90,0,0]) cylinder(d=16.2, h=wall + 2);
      translate([tray_x/2 + 8, -1, 22]) rotate([-90,0,0]) cylinder(d=5.2, h=wall + 2);
      translate([tray_x/2 + 22, -1, 22]) rotate([-90,0,0]) cylinder(d=6.2, h=wall + 2); // Kippschalter
    }
  }
}

// ============================================================================
//  Ausgabefach (1x) – mit Lichtschranke quer (Y) und Griffmulde
// ============================================================================
module well() {
  difference() {
    union() {
      // Boden
      cube([well_x, well_y, well_floor]);
      // dicke Längswände (vorn/hinten) – tragen die Lichtschranke
      for (y = [0, well_y - well_wy]) translate([0, y, 0]) cube([well_x, well_wy, well_ywall_h]);
      // niedrige Querwände unter den Abbruchkanten
      for (x = [0, well_x - wall]) translate([x, 0, 0]) cube([wall, well_y, well_xwall_h]);
    }
    // Fasen an den Querwänden (Karten rutschen hinein)
    for (x = [wall, well_x - wall]) translate([x, well_wy, well_xwall_h]) rotate([-90,0,0])
      cylinder(r=wall*1.4, h=well_in_y, $fn=4);
    // Lichtschranke: durchgehende Bohrung durch beide Längswände
    translate([beam_x, -1, beam_z]) rotate([-90,0,0]) cylinder(d=beam_d, h=well_y + 2);
    // Kabelrinne außen nach unten für die Lichtschranke
    for (y = [-1, well_y - 1.5]) translate([beam_x - 2, y, -1]) cube([4, 2.5, beam_z + 1]);
    // Griffmulde vorne
    translate([notch_x - notch_w/2, -1, well_floor + 6]) rcube([notch_w, well_wy + 2, 100], 4);
    // Verbindungsschrauben zu den Unterbauten + Mutterfallen (von unten einschieben)
    for (y = join_y) {
      translate([-1, y, join_z]) rotate([0,90,0]) cylinder(d=m3_clear, h=well_x + 2);
      for (x = [7, well_x - 7 - m3_nut_h])
        translate([x, y - m3_nut_w/2, -1]) cube([m3_nut_h + 0.2, m3_nut_w, join_z + 3.5 + 1]);
    }
    // Daumenloch im Boden: Stapel von unten herausdrücken
    translate([well_x/2, well_y/2, -1]) cylinder(d=20, h=well_floor + 2);
  }
}

// ============================================================================
//  Andruckgewicht (2x) – Hohlraum mit Münzen / M10-Muttern / Stahlkugeln füllen
// ============================================================================
module weight() {
  wx = in_x - 6; wy = in_y - 8; wh = 14;
  difference() {
    rcube([wx, wy, wh], 3);
    translate([2, 2, 2]) rcube([wx - 4, wy - 4, wh], 2);
  }
}

// ============================================================================
//  Zusammenbau-Ansicht
// ============================================================================
module tray_module(elec=false) {
  color("SteelBlue") side_box(elec);
  translate([0, 0, box_h]) {
    color("LightGray") tray();
    color("Orange") translate([gate_x, 0, floor_t + gate_gap]) rotate([90,0,90]) gate();
    color("DimGray") translate([x_w, y_face, 0]) motor_bracket();
    color("Black") translate([x_w, y_face + hub_offset, z_w]) rotate([-90,0,0]) wheel();
    color("Gold", 0.8) translate([wall + 3, y_in0 + 4, floor_t + 10]) weight();
    // Kartenstapel (Andeutung)
    color("White") translate([wall + 0.5, y_in0 + 1.5, floor_t]) cube([card_w, card_l, 8]);
  }
}

module assembly() {
  tray_module(false);
  translate([tray_x, 0, 0]) color("SeaGreen") well();
  translate([2*tray_x + well_x, tray_y, 0]) rotate([0,0,180]) tray_module(true);
  // Lichtschranke (Andeutung)
  color("Red") translate([tray_x + beam_x, -6, beam_z]) rotate([-90,0,0]) cylinder(d=0.8, h=well_y + 12);
}

// ============================================================================
if      (PART == "assembly")      assembly();
else if (PART == "tray")          tray();
else if (PART == "gate")          gate();
else if (PART == "motor_bracket") translate([0,0,bracket_len]) rotate([90,0,0]) motor_bracket();   // stehend
else if (PART == "wheel")         wheel();
else if (PART == "side_box")      side_box(false);
else if (PART == "side_box_elec") side_box(true);
else if (PART == "well")          well();
else if (PART == "weight")        weight();
