// ============================================================================
//  Arduino Poker-Kartenmischer MIT Austeil-Drehteller – parametrisches CAD
// ============================================================================
//  Eine Maschine:
//    OBEN   : zwei Schächte mischen (Riffle) -> Karten fallen in die Mitte
//    MITTE  : das Magazin fängt die Karten auf. Es ist gleichzeitig der Dealer:
//             Reibrad + Gate werfen die unterste Karte nach vorne (-Y) aus.
//             Ein Servo-Andruckarm drückt beim Austeilen auf den Stapel.
//    UNTEN  : Sockel mit NEMA-17-Schrittmotor + Lazy-Susan-Drehlager.
//             Die GESAMTE Oberseite dreht sich zu den Spielern.
//
//  Öffnen mit OpenSCAD (https://openscad.org), unten PART wählen, F6, STL-Export.
//  Kommandozeile: openscad -D 'PART="tray"' -o tray.stl card_shuffler.scad
//
//  Teile (Anzahl):
//    "assembly"       Gesamtansicht (nicht drucken)
//    "tray"           Mischschacht                                   (2x)
//    "gate"           Gate-Platte Mischschacht                       (2x)
//    "motor_bracket"  Halter N20-Motor                               (3x)
//    "wheel"          Reibrad-Nabe für 2 O-Ringe                     (3x)
//    "weight"         Andruckgewicht Mischschacht                    (2x)
//    "side_box"       Unterbau links                                 (1x)
//    "side_box_elec"  Unterbau rechts mit Arduino, Tastern, USB      (1x)
//    "magazine"       Magazin/Dealer (fängt Karten, wirft aus)       (1x)
//    "mag_gate"       Gate-Platte Magazin mit IR-Sender              (1x)
//    "mag_box"        Unterbau Magazin mit Wellennabe                (1x)
//    "servo_mount"    Halter für SG90-Servo                          (1x)
//    "press_arm"      Andruckarm                                     (1x)
//    "base"           Sockel (Topf) für NEMA 17, Treiber, Netzteil   (1x)
//    "base_lid"       Sockeldeckel mit Motorflansch                  (1x)
//
//  Koordinaten: X = Mischrichtung (links -> Mitte), Y = Kartenlängsseite,
//  -Y = Auswurfrichtung des Dealers ("vorne"), Z = oben.
// ============================================================================

PART = "assembly";

$fn = 64;

// ------------------------------ Karten --------------------------------------
card_w      = 63.5;   // Pokerkarte Breite  – Bridge: 57
card_l      = 88.9;   // Pokerkarte Länge
clear_x     = 2.5;
clear_y     = 3.1;

// ------------------------------ Allgemein -----------------------------------
wall        = 2.4;
tol         = 0.3;
m3_clear    = 3.4;
m3_tap      = 2.6;
m3_nut_w    = 5.8;
m3_nut_h    = 2.6;

// ------------------------------ Mischschacht --------------------------------
in_x        = card_w + clear_x;      // 66
in_y        = card_l + clear_y;      // 92
floor_t     = 3.5;
tray_wall_h = 30;
pillar      = 7;
gate_t      = 3;
lip         = 4;
gate_gap    = 0.5;

tray_x      = wall + in_x + gate_t + lip;          // 75.4
tray_y      = in_y + 2*wall + 2*pillar;            // 110.8
gate_x      = wall + in_x;
y_in0       = pillar + wall;

// ------------------------------ Reibrad / N20 -------------------------------
wheel_r       = 14.5;
wheel_core_d  = 26;
wheel_w       = 8;
oring_cs      = 3;
wheel_protr   = 1.0;
wheel_setback = 12;
shaft_d       = 3.0;
shaft_flat    = 2.5;
n20_a         = 12.3;
n20_b         = 10.3;
bracket_len   = 18;
stop_t        = 1.0;
hub_offset    = 1.5;

x_w   = gate_x - wheel_setback;
y_w   = y_in0 + in_y/2;
z_w   = floor_t + wheel_protr - wheel_r;           // -10
y_face= y_w - hub_offset - wheel_w/2;
br_ear= 12;

// ------------------------------ Unterbau Mischer ----------------------------
box_h       = 60;                    // höher: darunter liegt das Magazin
box_floor   = 2;
post        = 10;
peg_d       = 4;  peg_h = 1.8;
lip_z       = box_h + floor_t;       // 63.5 Abbruchkante (über Drehteller)
join_y      = [4.2, tray_y - 4.2];   // untere Verbindungsschrauben (Eck-Säulen)
join_z      = 12;
join2_y     = [24, tray_y - 24];     // obere Verbindungsschrauben (Magazinwände)
join2_z     = 45;

// ------------------------------ Magazin / Dealer ----------------------------
mbox_h      = 22;                    // Unterbau Magazin -> Magazinboden-Unterseite
mag_in_x    = card_w + 4.5;          // 68: Karten fallen von links/rechts hinein
mag_xw      = 6;                     // dicke Seitenwände (Schrauben fürs Gate)
mag_x       = mag_in_x + 2*mag_xw;   // 80
mag_lip     = 4;                     // Abbruchkante vor dem Gate
mag_front   = mag_lip + gate_t;      // 7: Innenfläche Gate
mag_in_y    = in_y;                  // 92
mag_y       = tray_y;                // 110.8
mag_back_t  = mag_y - mag_front - mag_in_y;        // 11.8 dicke Rückwand
mag_xwall_h = lip_z - mbox_h - 6;    // 35.5 (lokal) niedrige Seitenwände
mag_back_h  = lip_z - mbox_h + 10;   // 51.5 (lokal)
beam_zl     = 51 - mbox_h;           // Lichtschranke (lokal), über vollem Stapel
beam_xl     = mag_x/2 + 16;          // neben dem Andruckarm
beam_d      = 5.4;
mag_wheel_y = mag_front + 14;        // Radmitte hinter dem Gate
mag_face_x  = mag_x/2 - hub_offset - wheel_w/2;   // Getriebe-Stirnfläche
tcrt_a = 6.2;  tcrt_b = 10.6;        // Fenster TCRT5000 (Bauteil 10,2 x 5,8)
tcrt_x      = mag_x/2 + 17;
tcrt_y      = mag_front + 9;

// ------------------------------ Drehteller ----------------------------------
ax_x        = mag_x/2;               // Drehachse = Mitte Magazin
ax_y        = mag_y/2;
susan_h     = 8;                     // Bauhöhe Lazy-Susan 150 mm (6")
base_w      = 160;
base_h      = 55;                    // NEMA 17 (bis 48 mm lang) passt hinein
lid_t       = 4;
nema_hole   = 31;                    // Lochabstand NEMA 17
nema_boss   = 23;
nema_shaft  = 5.1;  nema_flat = 4.6; // Ø5 mit Abflachung auf 4,5
hub_d       = 16;
hub_top     = 19;                    // Nabe bis 19 mm über Kastenunterseite
cable_r     = 30;                    // Kabeldurchgang (Radius um die Achse)

// ------------------------------ Servo / Andruckarm --------------------------
sg_l = 22.9; sg_w = 12.6; sg_h = 22.7;   // SG90 Körper
sg_ear_z = 15.9;                          // Laschenebene über Unterseite
sg_ear_pitch = 27.8;
sg_shaft_off = 5.9;                       // Welle vom Körperende
arm_len     = 75;
pivot_y     = mag_y - 7;                  // Drehpunkt über der Rückwand
pivot_z     = mag_back_h + 3 + sg_w/2 + 2;
ear_plane_x = 23;                         // Laschenebene (lokal Magazin)
arm_x       = ear_plane_x + 13;           // Ebene des Arms

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
//  Motorhalter N20 (3x) – stehend drucken (Tunnel senkrecht)
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
//  Reibrad-Nabe (3x) – für 2 O-Ringe 22 x 3 mm (NBR) oder Gummi-Streifen
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
//  Verbindungs-Hilfen
// ============================================================================
function corners(w, d, inset) = [[inset, inset], [inset, d - inset],
                                 [w - inset, inset], [w - inset, d - inset]];
function peg_pos() = corners(tray_x, tray_y, post/2);

// ============================================================================
//  Unterbau Mischschacht (links: side_box, rechts: side_box_elec)
// ============================================================================
module side_box(elec=false) {
  difference() {
    union() {
      difference() {
        cube([tray_x, tray_y, box_h]);
        translate([wall, wall, box_floor]) cube([tray_x - 2*wall, tray_y - 2*wall, box_h]);
      }
      for (p = peg_pos()) translate([p[0] - post/2, p[1] - post/2, 0]) cube([post, post, box_h]);
      for (p = peg_pos()) translate([p[0], p[1], box_h]) cylinder(d=peg_d, h=peg_h);
    }
    // Verbindung zum Magazin-Unterbau (unten) und zum Magazin (oben)
    for (y = join_y)  translate([tray_x - 20, y, join_z])  rotate([0,90,0]) cylinder(d=m3_clear, h=30);
    for (y = join2_y) translate([tray_x - 10, y, join2_z]) rotate([0,90,0]) cylinder(d=m3_clear, h=20);
    // Kabeldurchführung zur Mitte
    translate([tray_x - wall - 1, tray_y/2 - 8, box_floor + 3]) cube([wall + 2, 16, 10]);
    translate([tray_x/2, tray_y/2, -1]) cylinder(d=30, h=box_floor + 2);
    if (elec) {
      // Außen-Stirnseite (X = 0): USB des Nano
      translate([-1, 30, box_floor + 4]) cube([wall + 2, 12, 8]);
      // Y = 0 (im Zusammenbau die RÜCKSEITE, zum Bediener): 2 Taster + LED
      translate([tray_x/2 - 18, -1, 30]) rotate([-90,0,0]) cylinder(d=16.2, h=wall + 2);
      translate([tray_x/2 + 2,  -1, 30]) rotate([-90,0,0]) cylinder(d=16.2, h=wall + 2);
      translate([tray_x/2 + 20, -1, 30]) rotate([-90,0,0]) cylinder(d=5.2,  h=wall + 2);
    }
  }
}

// ============================================================================
//  Magazin = Auffangfach + Dealer (1x) – Boden nach unten drucken
// ============================================================================
module magazine() {
  difference() {
    union() {
      cube([mag_x, mag_y, floor_t]);                                    // Boden
      for (x = [0, mag_x - mag_xw])                                     // Seitenwände
        translate([x, mag_front, 0]) cube([mag_xw, mag_y - mag_front, mag_xwall_h]);
      translate([0, mag_y - mag_back_t, 0]) cube([mag_x, mag_back_t, mag_back_h]);  // Rückwand
    }
    // Fasen oben an den Seitenwänden: Karten rutschen nach innen
    for (x = [mag_xw, mag_x - mag_xw]) translate([x, mag_front - 1, mag_xwall_h])
      rotate([-90,0,0]) cylinder(r=mag_xw*0.9, h=mag_in_y + 2, $fn=4);
    // Reibrad-Schlitz (Achse in X)
    translate([mag_x/2 - wheel_w/2 - 1.5, mag_wheel_y - 12, -1]) rcube([wheel_w + 3, 24, floor_t + 2], 1.5);
    // Senkschrauben Motorhalter (Halter um -90° gedreht)
    for (dy = [-br_ear, br_ear])
      translate([mag_face_x - bracket_len/2, mag_wheel_y + dy, 0]) countersink_m3(floor_t);
    // TCRT5000-Fenster ("Magazin leer")
    translate([tcrt_x - tcrt_a/2, tcrt_y - tcrt_b/2, -1]) cube([tcrt_a, tcrt_b, floor_t + 2]);
    // Gate-Schrauben (in die Stirnflächen der Seitenwände, Richtung +Y)
    for (x = [mag_xw/2, mag_x - mag_xw/2])
      translate([x, mag_front - 0.01, floor_t + 15]) rotate([-90,0,0]) cylinder(d=m3_tap, h=10);
    // IR-Empfänger in der Rückwand
    translate([beam_xl, mag_y - mag_back_t - 1, beam_zl]) rotate([-90,0,0]) cylinder(d=beam_d, h=mag_back_t + 2);
    // obere Verbindung zu den Mischer-Unterbauten: Loch + Mutterschlitz von oben
    for (y = join2_y) {
      translate([-1, y, join2_z - mbox_h]) rotate([0,90,0]) cylinder(d=m3_clear, h=mag_x + 2);
      for (x = [1.6, mag_x - 1.6 - m3_nut_h - 0.2])
        translate([x, y - m3_nut_w/2, join2_z - mbox_h - m3_nut_w/2]) cube([m3_nut_h + 0.2, m3_nut_w, 50]);
    }
    // Zentrierlöcher für die Stifte des Unterbaus
    for (p = corners(mag_x, mag_y, post/2)) translate([p[0], p[1], -0.01]) cylinder(d=peg_d + tol, h=2);
    // Schraubenlöcher für Servohalter (oben in der Rückwand)
    for (x = [11, 20]) translate([x, mag_y - mag_back_t/2, mag_back_h - 10]) cylinder(d=m3_tap, h=11);
    // Abbruchkante abrunden
    translate([-1, 0, floor_t]) rotate([0,90,0]) cylinder(r=1, h=mag_x + 2);
  }
}

// Gate-Platte des Magazins (flach drucken) mit Halter für die IR-LED (Sender)
mag_gate_h = mag_back_h - floor_t - gate_gap;
module mag_gate() {
  slot_c = 15 - gate_gap;
  led_z  = beam_zl - floor_t - gate_gap;
  difference() {
    union() {
      cube([mag_x, mag_gate_h, gate_t]);
      translate([beam_xl, led_z, 0]) cylinder(d=10, h=gate_t + 6);    // LED-Halter (außen)
    }
    for (x = [mag_xw/2, mag_x - mag_xw/2])
      hull() for (dy = [-2.5, 2.5]) translate([x, slot_c + dy, -1]) cylinder(d=m3_clear, h=gate_t + 2);
    translate([beam_xl, led_z, -1]) cylinder(d=beam_d, h=gate_t + 8);
    translate([-1, mag_gate_h, gate_t]) rotate([0,90,0]) cylinder(r=1.5, h=mag_x + 2, $fn=4);
  }
}

// ============================================================================
//  Unterbau Magazin (1x) – mit Nabe für die NEMA-17-Welle
// ============================================================================
module mag_box() {
  bf = 3;
  difference() {
    union() {
      difference() {
        cube([mag_x, mag_y, mbox_h]);
        translate([wall, wall, bf]) cube([mag_x - 2*wall, mag_y - 2*wall, mbox_h]);
      }
      for (p = corners(mag_x, mag_y, post/2)) {
        translate([p[0] - post/2, p[1] - post/2, 0]) cube([post, post, mbox_h]);
        translate([p[0], p[1], mbox_h]) cylinder(d=peg_d, h=peg_h);
      }
      translate([ax_x, ax_y, 0]) cylinder(d=hub_d, h=hub_top);       // Nabe
    }
    // D-Bohrung für die Motorwelle (von unten)
    translate([ax_x, ax_y, -1]) intersection() {
      cylinder(d=nema_shaft, h=hub_top + 2);
      translate([-nema_shaft/2, -nema_shaft/2, 0]) cube([nema_flat, nema_shaft, hub_top + 2]);
    }
    // Klemmschraube (Madenschraube M3) quer in die Nabe, auf die Abflachung
    translate([ax_x, ax_y, hub_top - 6]) rotate([0,90,0]) cylinder(d=m3_tap, h=hub_d);
    // untere Verbindung zu den Mischer-Unterbauten: Loch + Mutterschlitz von oben
    for (y = join_y) {
      translate([-1, y, join_z]) rotate([0,90,0]) cylinder(d=m3_clear, h=mag_x + 2);
      for (x = [5, mag_x - 5 - m3_nut_h - 0.2])
        translate([x, y - m3_nut_w/2, join_z - m3_nut_w/2]) cube([m3_nut_h + 0.2, m3_nut_w, 50]);
    }
    // Kabel: seitlich zu den Mischer-Unterbauten und nach unten zum Sockel
    for (x = [-1, mag_x - wall - 1]) translate([x, mag_y/2 - 8, bf + 3]) cube([wall + 2, 16, 10]);
    translate([ax_x + cable_r, ax_y, -1]) cylinder(d=12, h=bf + 2);
  }
}

// ============================================================================
//  Servohalter (SG90) und Andruckarm
// ============================================================================
module servo_mount() {
  // lokale Koordinaten = Magazin-Koordinaten
  body_cy = pivot_y + (sg_l/2 - sg_shaft_off);     // Körper ragt nach hinten
  difference() {
    union() {
      // Fuß auf der Rückwand
      translate([6, mag_y - mag_back_t, mag_back_h]) cube([ear_plane_x - 6, mag_back_t, 3]);
      // senkrechte Platte mit Fenster (Laschen liegen auf der +X-Seite an)
      translate([ear_plane_x - 3, body_cy - 20, mag_back_h])
        cube([3, 40, pivot_z - mag_back_h + sg_w/2 + 5]);
    }
    for (x = [11, 20]) translate([x, mag_y - mag_back_t/2, mag_back_h - 1]) countersink_m3(4.01);
    translate([ear_plane_x - 4, body_cy - sg_l/2, pivot_z - sg_w/2]) cube([5, sg_l, sg_w]);
    for (dy = [-sg_ear_pitch/2, sg_ear_pitch/2])
      translate([ear_plane_x - 4, body_cy + dy, pivot_z]) rotate([0,90,0]) cylinder(d=2.2, h=5);
  }
}

module press_arm() {
  // flach liegend; Drehpunkt im Ursprung, Arm entlang +X, Druckrolle am Ende
  difference() {
    union() {
      hull() {
        cylinder(d=12, h=5);
        translate([arm_len, 0, 0]) cylinder(d=8, h=5);
      }
      translate([arm_len, 0, 0]) cylinder(d=12, h=5);
    }
    // Loch für Rundstab Ø6 x 40 mm (Holzdübel) = Druckrolle quer über die Karte
    translate([arm_len, 0, -1]) cylinder(d=6.2, h=7);
    translate([0, 0, -1]) cylinder(d=2.5, h=10);          // Hornschraube
    translate([0, 0, 3.4]) cylinder(d=7.6, h=5);          // Hornnabe
    translate([-3.5, -2.9, 3.4]) cube([22, 5.8, 5]);      // einarmiges Servohorn
  }
}

// ============================================================================
//  Sockel mit NEMA 17 (steht still) – Deckel trägt Motor und Drehlager
// ============================================================================
module base() {
  difference() {
    union() {
      difference() {
        rcube([base_w, base_w, base_h], 6);
        translate([wall, wall, 2]) rcube([base_w - 2*wall, base_w - 2*wall, base_h], 4);
      }
      for (p = corners(base_w, base_w, 8)) translate([p[0], p[1], 0]) cylinder(d=12, h=base_h);
    }
    for (p = corners(base_w, base_w, 8)) translate([p[0], p[1], base_h - 12]) cylinder(d=m3_tap, h=13);
    // Rückseite (+Y): DC-Buchse und Schalter
    translate([base_w/2 - 15, base_w - wall - 1, 20]) rotate([-90,0,0]) cylinder(d=8, h=wall + 2);
    translate([base_w/2 + 15, base_w - wall - 1, 20]) rotate([-90,0,0]) cylinder(d=6.2, h=wall + 2);
    // Markierung vorne (-Y) = Richtung Spieler 1
    translate([base_w/2, -1, base_h - 6]) rotate([-90,0,0]) cylinder(d=4, h=2, $fn=3);
    // Lüftung
    for (i = [-2:2]) translate([base_w/2 + i*12 - 2, -1, 8]) cube([4, wall + 2, 25]);
  }
}

module base_lid() {
  difference() {
    rcube([base_w, base_w, lid_t], 6);
    translate([base_w/2, base_w/2, -1]) cylinder(d=nema_boss, h=lid_t + 2);
    for (x = [-1, 1], y = [-1, 1])
      translate([base_w/2 + x*nema_hole/2, base_w/2 + y*nema_hole/2, 0]) countersink_m3(lid_t);
    translate([base_w/2 + cable_r, base_w/2, -1]) cylinder(d=14, h=lid_t + 2);
    for (p = corners(base_w, base_w, 8)) translate([p[0], p[1], 0]) countersink_m3(lid_t);
    translate([base_w/2 - 2, -1, lid_t - 1.5]) cube([4, 6, 2]);      // Markierung "vorne"
  }
}

// ============================================================================
//  Zusammenbau
// ============================================================================
module tray_module(elec=false) {
  color("SteelBlue") side_box(elec);
  translate([0, 0, box_h]) {
    color("LightGray") tray();
    color("Orange") translate([gate_x, 0, floor_t + gate_gap]) rotate([90,0,90]) gate();
    color("DimGray") translate([x_w, y_face, 0]) motor_bracket();
    color("Black") translate([x_w, y_face + hub_offset, z_w]) rotate([-90,0,0]) wheel();
    color("Gold", 0.8) translate([wall + 3, y_in0 + 4, floor_t + 10]) weight();
    color("White") translate([wall + 0.5, y_in0 + 1.5, floor_t]) cube([card_w, card_l, 8]);
  }
}

module magazine_module(arm_down=false) {
  color("CadetBlue") mag_box();
  translate([0, 0, mbox_h]) {
    color("SeaGreen") magazine();
    color("Orange") translate([0, mag_front, floor_t + gate_gap]) rotate([90,0,0]) mag_gate();
    color("DimGray") translate([mag_face_x, mag_wheel_y, 0]) rotate([0,0,-90]) motor_bracket();
    color("Black") translate([mag_face_x + hub_offset, mag_wheel_y, z_w]) rotate([0,90,0]) wheel();
    color("Peru") servo_mount();
    color("RoyalBlue") translate([ear_plane_x, pivot_y + (sg_l/2 - sg_shaft_off) - sg_l/2, pivot_z - sg_w/2])
      cube([sg_h - sg_ear_z + 4, sg_l, sg_w]);                         // SG90 (Andeutung)
    // Andruckarm: oben (Mischen) bzw. auf dem Stapel (Austeilen)
    color("Tomato") translate([arm_x + 2.5, pivot_y, pivot_z])
      rotate([arm_down ? 128 : -10, 0, 0]) rotate([0, -90, 0]) {
        press_arm();
        color("BurlyWood") translate([arm_len, 0, -17.5]) cylinder(d=6, h=40);   // Rundstab
      }
    color("White") translate([mag_xw + 2, mag_front + 1, floor_t]) cube([card_w, card_l, 12]);
    color("Red") translate([beam_xl, -8, beam_zl]) rotate([-90,0,0]) cylinder(d=0.8, h=mag_y + 16);
  }
}

module rotating_unit(arm_down=false) {
  tray_module(false);
  translate([tray_x, 0, 0]) magazine_module(arm_down);
  translate([2*tray_x + mag_x, tray_y, 0]) rotate([0,0,180]) tray_module(true);
}

module assembly() {
  cx = tray_x + ax_x;  cy = ax_y;
  translate([cx - base_w/2, cy - base_w/2, 0]) {
    color("SlateGray") base();
    color("LightSlateGray") translate([0, 0, base_h]) base_lid();
  }
  color("Silver", 0.5) translate([cx - 75, cy - 75, base_h + lid_t]) cube([150, 150, susan_h]);
  translate([0, 0, base_h + lid_t + susan_h]) rotating_unit(false);
}

// ============================================================================
if      (PART == "assembly")      assembly();
else if (PART == "magazine_view") magazine_module(true);
else if (PART == "tray")          tray();
else if (PART == "gate")          gate();
else if (PART == "motor_bracket") translate([0,0,bracket_len]) rotate([90,0,0]) motor_bracket();
else if (PART == "wheel")         wheel();
else if (PART == "weight")        weight();
else if (PART == "side_box")      side_box(false);
else if (PART == "side_box_elec") side_box(true);
else if (PART == "magazine")      magazine();
else if (PART == "mag_gate")      mag_gate();
else if (PART == "mag_box")       mag_box();
else if (PART == "servo_mount")   translate([0, 0, -mag_back_h]) servo_mount();
else if (PART == "press_arm")     press_arm();
else if (PART == "base")          base();
else if (PART == "base_lid")      base_lid();
