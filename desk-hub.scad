// desk-hub: a modular laptop riser with cable trays, a document slot and clip-on organizers.
// Sized for the ASUS ROG Strix G18 (2025, G815): 399 x 299 mm, 23.5-32 mm thick, 3.2-3.4 kg.
// Measure your laptop's footprint at its underside and set laptop_d and laptop_w; every
// length follows from them. Parts lock with printed keys, no glue or screws.
//
// PETG only where the laptop touches (rail caps, end caps). Everything else is PLA.

part = "assembly";
// assembly | vertical | parts | tests | gauge
// segment | rail_cap | rail_cap_lip | end_cap | spine | bar | cradle
// key_wall | key_tray | key_floor | key_bar
// pen_cup | phone_stand | catch_tray | cable_dock | headphone_hook | fit_coupon
// gauge_corner | gauge_corner_mirror | gauge_strap_x | gauge_strap_y | gauge_key

$fn = 40;
fit = 0.15;           // clearance per side on every joint

laptop_d = 299;       // front to back, runs along the cheeks
laptop_w = 399;       // left to right, spans between the cheeks
gap = 1;              // play between the laptop and each stop

deck = 55;            // laptop underside height
cap_t = 5;            // PETG rail cap thickness
wall_top = deck - cap_t;
rail_w = 20;          // how far the rail reaches under the laptop edge
lip_t = 4;            // side lip: stops the laptop sliding sideways
lip_h = 6;            // rubber feet lift the chassis 2-3 mm off the rail
lip_len = 30;
stop_h = 7;           // end stop height above the deck
stop_reach = 35;      // end stop reaches this far in, past the chamfered corners

tray_wall = 8;
tray_w = 34;
floor_t = 3;
tray_h = 28;

wall_y0 = tray_wall + tray_w;     // outer face of the bearing wall = laptop edge
cheek_w = wall_y0 + rail_w;       // inner face of the cheek
cap_y0 = wall_y0 - gap - lip_t;   // rail cap reaches over the tray to carry the lip

ec_t = 22;                        // end cap thickness, stop plate in its middle
ec_plate = 5;
ec_stop = (ec_t - ec_plate) / 2;  // stop face distance from the end cap's inner face
seg_len = (laptop_d + 2 * gap - 2 * ec_stop) / 3;
cheek_len = 3 * seg_len + 2 * ec_t;
cheek_x0 = -(ec_t - ec_stop + gap);   // cheek start in laptop coordinates

span = laptop_w - 2 * rail_w;     // between the inner faces
spine_w = 50;
spine_wall = 6;
spine_floor = 5;
spine_h = 32;
bar_t = 16;
bar_h = 14;
bar_z0 = wall_top - bar_h;        // documents fit under this

// Joints. A key is a double dovetail; each side gets a half socket.
k_wall = [10, 14, 8];             // neck, tail width, depth per side
k_tray = [4, 6, 5];
k_floor = [14, 20, 10];
k_bar = [8, 12, 8];
acc_tail = [8, 12, 6];
acc_z = [7, 27];                  // accessory tail height band

// ---------------------------------------------------------------- helpers

module tail2d(k, grow = 0) {
    offset(delta = grow) polygon([[-k[0]/2, 0], [k[0]/2, 0], [k[1]/2, k[2]], [-k[1]/2, k[2]]]);
}
// Half socket cut into a face: origin on the face, pointing +Y into the material.
module socket(k, z0, z1) translate([0, -0.01, z0]) linear_extrude(z1 - z0) tail2d(k, fit);
module key(k, h) linear_extrude(h) union() { tail2d(k); mirror([0, 1, 0]) tail2d(k); }

module rbox(s, r) {   // box rounded around Y, for windows through a wall
    hull() for (x = [r, s[0] - r], z = [r, s[2] - r]) translate([x, 0, z]) rotate([-90, 0, 0]) cylinder(r = r, h = s[1]);
}
module rcube(s, r) {  // box rounded around Z
    hull() for (x = [r, s[0] - r], y = [r, s[1] - r]) translate([x, y, 0]) cylinder(r = r, h = s[2]);
}

// ---------------------------------------------------------------- cheek

// One of three identical PLA segments per cheek. Symmetric end to end, so any segment
// goes anywhere, either way round.
module segment() {
    c = seg_len / 2;
    difference() {
        union() {
            cube([seg_len, cheek_w, floor_t]);
            cube([seg_len, tray_wall, tray_h]);
            translate([0, wall_y0, 0]) cube([seg_len, rail_w, wall_top]);
        }
        // Keys to the neighbours.
        for (e = [[0, 0], [seg_len, 180]]) translate([e[0], 0, 0]) rotate(e[1]) {
            translate([0, e[1] ? -(wall_y0 + rail_w / 2) : wall_y0 + rail_w / 2, 0]) rotate(-90) socket(k_wall, -1, wall_top + 1);
            translate([0, e[1] ? -tray_wall / 2 : tray_wall / 2, 0]) rotate(-90) socket(k_tray, -1, tray_h + 1);
        }
        // Spine floor key and bar key, on the inner face at mid length.
        translate([c, cheek_w, 0]) rotate(180) socket(k_floor, -1, spine_floor + fit);
        translate([c, cheek_w, 0]) rotate(180) socket(k_bar, bar_z0 - fit, wall_top + 1);
        // Cable pass-through from the tray to the spine.
        translate([c - 16, wall_y0 - 1, spine_floor + 1]) rbox([32, rail_w + 2, spine_h - spine_floor - 1], 5);
        // Air and weight.
        for (x = [11, seg_len - 29]) translate([x, wall_y0 - 1, 10]) rbox([18, rail_w + 2, 22], 6);
        // Accessory sockets on the outside of the tray.
        for (x = [c - 25, c + 25]) translate([x, 0, 0]) socket(acc_tail, acc_z[0] - 1, tray_h + 1);
        // Cable comb.
        for (x = [c - 37, c - 12.5, c, c + 12.5, c + 37]) translate([x - 3, -1, tray_h - 12]) cube([6, tray_wall + 2, 13]);
    }
}

// PETG cap the laptop sits on. Flanges hug the wall; the lip variant goes on the end segments.
module rail_cap(lip = false) {
    c = seg_len / 2;
    l = seg_len - 0.4;
    translate([0.2, 0, 0]) {
        translate([0, cap_y0, wall_top]) cube([l, cheek_w - cap_y0, cap_t]);
        translate([0, wall_y0 - fit - 3, wall_top - 4]) cube([l, 3, 4.01]);
        difference() {
            translate([0, cheek_w + fit, wall_top - 4]) cube([l, 3, 4.01]);
            translate([c - 0.2 - 11, cheek_w - 1, wall_top - 5]) cube([22, 6, 6]);
        }
        if (lip) translate([c - 0.2 - lip_len / 2, cap_y0, deck - 0.01]) cube([lip_len, lip_t, lip_h]);
    }
}

// PETG end cap: closes the tray and stops the laptop sliding off the end. Symmetric in its
// thickness, so it fits either end of either cheek.
module end_cap() {
    p0 = ec_stop;
    difference() {
        union() {
            cube([ec_t, cheek_w, floor_t]);
            cube([ec_t, tray_wall, tray_h]);
            translate([p0, 0, 0]) cube([ec_plate, wall_y0, tray_h]);
            translate([0, wall_y0, 0]) cube([ec_t, rail_w, deck]);
            translate([p0, cap_y0, 0]) cube([ec_plate, cheek_w - cap_y0 + stop_reach - rail_w, deck + stop_h]);
        }
        for (e = [[0, 0], [ec_t, 180]]) translate([e[0], 0, 0]) rotate(e[1]) {
            translate([0, e[1] ? -(wall_y0 + rail_w / 2) : wall_y0 + rail_w / 2, 0]) rotate(-90) socket(k_wall, -1, wall_top + fit);
            translate([0, e[1] ? -tray_wall / 2 : tray_wall / 2, 0]) rotate(-90) socket(k_tray, -1, tray_h + 1);
        }
    }
}

// ---------------------------------------------------------------- crossings

// PLA spine: carries cables under the laptop between the trays and ties the cheeks at the
// bottom. Two identical halves.
module spine() {
    l = span / 2;
    difference() {
        union() {
            cube([spine_w, l, spine_floor]);
            for (x = [0, spine_w - spine_wall]) cube([spine_wall, l, spine_h]);
        }
        for (e = [[0, 0], [l, 180]]) translate([spine_w / 2, e[0], 0]) rotate(e[1]) translate([0, 0, 0])
            mirror([0, 0, 0]) socket(k_floor, -1, spine_floor + 1);
    }
}

// PLA bar: ties the cheeks at the top, 1 mm below the laptop so it never carries heat.
// Two identical halves; the rail cap above locks its key in.
module bar() {
    l = span / 2;
    difference() {
        cube([bar_t, l, bar_h]);
        for (e = [[0, 0], [l, 180]]) translate([bar_t / 2, e[0], 0]) rotate(e[1]) socket(k_bar, -1, bar_h + 1);
    }
}

// ---------------------------------------------------------------- vertical stand

cradle_len = 200;
cradle_w = 50;
slot_w = 25.5;        // front edge is 23.5 mm
slot_z = spine_h + 4; // the spine runs under the laptop between the cradles
cradle_h = slot_z + 60;

// PLA cradle: holds the laptop on its front edge, exhaust up. Two per stand, tied by one
// spine half that doubles as the cable run.
module cradle() {
    c = cradle_len / 2;
    blk = slot_w + 2 * 12;
    difference() {
        union() {
            rcube([cradle_len, cradle_w, 6], 6);
            translate([c - blk / 2, 0, 0]) cube([blk, cradle_w, cradle_h]);
            for (s = [-1, 1]) hull() {
                translate([c + s * blk / 2 - (s > 0 ? 0 : 6), cradle_w / 2 - 3, 0]) cube([6, 6, cradle_h - 10]);
                translate([s > 0 ? cradle_len - 12 : 6, cradle_w / 2 - 3, 0]) cube([6, 6, 6]);
            }
        }
        translate([c - slot_w / 2, -1, slot_z]) cube([slot_w, cradle_w + 2, cradle_h]);
        // Lead-in chamfer at the slot mouth.
        translate([c, -1, cradle_h]) rotate([-90, 0, 0]) linear_extrude(cradle_w + 2)
            polygon([[-slot_w / 2 - 4, 0.01], [slot_w / 2 + 4, 0.01], [slot_w / 2, 4], [-slot_w / 2, 4]]);
        for (e = [[0, 0], [cradle_w, 180]]) translate([c, e[0], 0]) rotate(e[1]) socket(k_floor, -1, spine_floor + fit);
        // Cable window through the block above the spine.
        translate([c - slot_w / 2 - 13, cradle_w / 2 - 12, 8]) cube([blk + 2, 24, spine_h - 10]);
    }
}

// ---------------------------------------------------------------- organizers (PLA)
// Back face at y = 0 against the tray, body toward -Y. They slide down into the sockets.

module acc_tails(xs) for (x = xs) translate([x, 0, acc_z[0]]) linear_extrude(acc_z[1] - acc_z[0]) tail2d(acc_tail);
module back_block(x0, x1) translate([x0, -6, 0]) cube([x1 - x0, 6, acc_z[1]]);

module pen_cup() {
    s = 56;
    back_block(s / 2 - 10, s / 2 + 10);
    acc_tails([s / 2]);
    translate([0, -s - 6, 0]) difference() {
        rcube([s, s, 100], 8);
        translate([2, 2, 2]) rcube([s - 4, s - 4, 100], 6);
    }
}

module phone_stand() {
    w = 80;
    back_block(5, 25); back_block(w - 25, w - 5);
    acc_tails([15, 65]);
    translate([0, -62, 0]) cube([w, 62, 5]);
    translate([0, -62, 0]) cube([w, 5, 16]);
    hull() { translate([0, -42, 0]) cube([w, 6, 5]); translate([0, -18, 92]) cube([w, 6, 6]); }
    for (x = [0, w - 6]) hull() {
        translate([x, -42, 0]) cube([6, 36, 5]);
        translate([x, -18, 92]) cube([6, 6, 6]);
    }
}

module catch_tray() {
    w = 130;
    back_block(25, 105);
    acc_tails([w / 2 - 25, w / 2 + 25]);
    translate([0, -81, 0]) difference() {
        rcube([w, 75, 30], 10);
        translate([2.4, 2.4, 2]) rcube([w - 4.8, 75 - 4.8, 30], 8);
    }
}

module cable_dock() {
    w = 80;
    back_block(0, w);
    acc_tails([15, 65]);
    translate([0, -30, 0]) difference() {
        cube([w, 24, 36]);
        for (i = [0 : 4]) translate([8 + i * 16, 0, 0]) {
            translate([0, 12, 10]) cylinder(d = 8, h = 30);
            translate([-2.75, -1, 10]) cube([5.5, 14, 30]);
        }
    }
}

module headphone_hook() {
    back_block(20, 40);
    acc_tails([30]);
    translate([0, -70, 0]) rcube([60, 64, 5], 8);
    translate([20, -26, 0]) cube([20, 20, 170]);
    translate([20, -86, 160]) cube([20, 80, 10]);
    translate([20, -86, 160]) cube([20, 8, 24]);
    // 45 degree brace so the arm prints without supports.
    hull() { translate([20, -26, 100]) cube([20, 6, 6]); translate([20, -86, 160]) cube([20, 6, 6]); }
}

// ---------------------------------------------------------------- tests

// Every socket profile in one PLA block. Print it with the four keys and one accessory
// tail; each should slide in by hand without wobble.
module fit_coupon() {
    difference() {
        cube([118, 26, 16]);
        translate([12, 26, 0]) rotate(180) socket(k_wall, -1, 17);
        translate([36, 26, 0]) rotate(180) socket(k_tray, -1, 17);
        translate([58, 26, 0]) rotate(180) socket(k_floor, -1, 17);
        translate([84, 26, 0]) rotate(180) socket(k_bar, -1, 17);
        translate([106, 0, 0]) socket(acc_tail, -1, 17);
        for (i = [0 : 4]) translate([[12, 36, 58, 84, 106][i] - 1.5, 10, 15]) cube([3, 6, 2]);
    }
}
module test_tail() { translate([0, 0, 0]) linear_extrude(16) tail2d(acc_tail); translate([-10, -8, 0]) cube([20, 8, 16]); }

// Footprint gauge: the riser's laptop pocket at desk height, with the stops and lips where
// the real ones sit. Four corners tied by straps and bar keys; the laptop should drop in
// with `gap` to spare at every stop and lip. Laptop frame, rear port-side corner at origin.
gauge_t = 4;
gauge_x0 = -gap - ec_plate;       // back of the stop
gauge_y0 = -gap - lip_t;          // back of the lip
gauge_arm = 20;

module gauge_corner() {
    x1 = end_seg_mid[0] + lip_len / 2 + 10;
    y1 = stop_reach + 10;
    difference() {
        union() {
            translate([gauge_x0, gauge_y0, 0]) cube([x1 - gauge_x0, rail_w - gauge_y0, gauge_t]);
            translate([gauge_x0, gauge_y0, 0]) cube([gauge_arm, y1 - gauge_y0, gauge_t]);
            translate([gauge_x0, gauge_y0, 0]) cube([ec_plate, stop_reach - gauge_y0, gauge_t + stop_h]);
            translate([end_seg_mid[0] - lip_len / 2, gauge_y0, 0]) cube([lip_len, lip_t, gauge_t + lip_h]);
        }
        translate([x1, (gauge_y0 + rail_w) / 2, 0]) rotate(90) socket(k_bar, -1, gauge_t + 1);
        translate([gauge_x0 + gauge_arm / 2, y1, 0]) rotate(180) socket(k_bar, -1, gauge_t + 1);
    }
}
module gauge_strap(l, w) difference() {
    cube([w, l, gauge_t]);
    for (e = [[0, 0], [l, 180]]) translate([w / 2, e[0], 0]) rotate(e[1]) socket(k_bar, -1, gauge_t + 1);
}
module gauge_strap_x() gauge_strap(laptop_d - 2 * (end_seg_mid[0] + lip_len / 2 + 10), rail_w - gauge_y0);
module gauge_strap_y() gauge_strap((laptop_w - 2 * (stop_reach + 10)) / 2, gauge_arm);
module gauge_key() key(k_bar, gauge_t - 0.4);

module gauge_side() {
    x1 = end_seg_mid[0] + lip_len / 2 + 10;
    y1 = stop_reach + 10;
    translate([x1, rail_w, 0]) rotate(-90) gauge_strap_x();
    color("#7c8794") for (x = [x1, laptop_d - x1]) translate([x, (gauge_y0 + rail_w) / 2, 0]) rotate(90) gauge_key();
    for (m = [0, 1]) translate([m * laptop_d, 0, 0]) mirror([m, 0, 0]) {
        gauge_corner();
        translate([gauge_x0, y1, 0]) gauge_strap_y();
        color("#7c8794") translate([gauge_x0 + gauge_arm / 2, y1, 0]) gauge_key();
    }
}
module gauge() {
    gauge_side();
    translate([laptop_d, laptop_w, 0]) rotate(180) gauge_side();
    color("#7c8794") for (x = [gauge_x0 + gauge_arm / 2, laptop_d - gauge_x0 - gauge_arm / 2])
        translate([x, laptop_w / 2, 0]) gauge_key();
}

// ---------------------------------------------------------------- placement

// Laptop frame: X 0 at the laptop's rear (exhaust) edge, Y 0 at its port edge, Z up.
seg_x = [for (i = [0 : 2]) cheek_x0 + ec_t + i * seg_len];
end_seg_mid = [seg_x[0] + seg_len / 2, seg_x[2] + seg_len / 2];

module cheek(lips = true) {
    translate([cheek_x0, -wall_y0, 0]) {
        color("#d8d4cc") for (i = [0 : 2]) translate([ec_t + i * seg_len, 0, 0]) segment();
        color("#f08a3c") {
            for (x = [0, ec_t + 3 * seg_len]) translate([x, 0, 0]) end_cap();
            for (i = [0 : 2]) translate([ec_t + i * seg_len, 0, 0]) rail_cap(lips && i != 1);
        }
    }
}

module riser() {
    cheek();
    translate([laptop_d, laptop_w, 0]) rotate(180) cheek();
    color("#7c8794") translate([end_seg_mid[0] - spine_w / 2, rail_w, 0]) {
        spine(); translate([0, span / 2, 0]) spine();
    }
    color("#7c8794") for (x = end_seg_mid) translate([x - bar_t / 2, rail_w, bar_z0]) {
        bar(); translate([0, span / 2, 0]) bar();
    }
}

module organizers() {
    near = -wall_y0;
    // Port side: phone stand and pen cup.
    translate([end_seg_mid[1] - 40, near, 0]) phone_stand();
    translate([end_seg_mid[0] + 25 - 28, near, 0]) pen_cup();
    // Wall side, turned to face the wall.
    translate([laptop_d, laptop_w, 0]) rotate(180) {
        translate([end_seg_mid[0] - 65 + (laptop_d - 2 * end_seg_mid[0]) * 0, -wall_y0, 0]) catch_tray();
        translate([end_seg_mid[1] + 25 - 30, -wall_y0, 0]) headphone_hook();
        translate([seg_x[1] + seg_len / 2 - 40, -wall_y0, 0]) cable_dock();
    }
}

module vertical() {
    for (y = [0, cradle_w + span / 2]) translate([-cradle_len / 2, y, 0]) color("#d8d4cc") cradle();
    color("#7c8794") translate([-spine_w / 2, cradle_w, 0]) spine();
}

module layout(parts) for (i = [0 : len(parts) - 1]) translate([(i % 4) * 230, -floor(i / 4) * 230, 0]) children(i);

if (part == "assembly") { riser(); color("#5b9bd5") organizers(); }
if (part == "vertical") vertical();
if (part == "segment") segment();
if (part == "rail_cap") translate([0, -cap_y0, -wall_top + 4]) rail_cap(false);
if (part == "rail_cap_lip") translate([0, -cap_y0, -wall_top + 4]) rail_cap(true);
if (part == "end_cap") end_cap();
if (part == "spine") spine();
if (part == "bar") bar();
if (part == "cradle") cradle();
if (part == "key_wall") key(k_wall, wall_top - 0.4);
if (part == "key_tray") key(k_tray, tray_h - 0.4);
if (part == "key_floor") key(k_floor, spine_floor - 0.4);
if (part == "key_bar") key(k_bar, bar_h - 0.4);
if (part == "pen_cup") pen_cup();
if (part == "phone_stand") phone_stand();
if (part == "catch_tray") catch_tray();
if (part == "cable_dock") cable_dock();
if (part == "headphone_hook") headphone_hook();
if (part == "fit_coupon") fit_coupon();
if (part == "test_tail") test_tail();
if (part == "gauge") gauge();
if (part == "gauge_corner") gauge_corner();
if (part == "gauge_corner_mirror") mirror([1, 0, 0]) gauge_corner();
if (part == "gauge_strap_x") gauge_strap_x();
if (part == "gauge_strap_y") gauge_strap_y();
if (part == "gauge_key") gauge_key();
