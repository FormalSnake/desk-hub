// Renders for the README. The laptop is a stand-in: chamfered corners, wedge base, lid
// hinged ahead of the rear exhaust block.
include <desk-hub.scad>
part = "none";

view = "hero";        // hero | lid | docs | exploded | vertical | tests
lid = 0;

hinge_x = 26;         // exhaust block sits behind the hinge
chamfer = 8;

module footprint(h) linear_extrude(h) offset(delta = chamfer, chamfer = true) offset(delta = -chamfer)
    square([laptop_d, laptop_w]);

module laptop(z = deck, upright = false) {
    translate([0, 0, z + 2]) {
        color("#202329", 0.6) intersection() {
            footprint(30);
            hull() { cube([1, laptop_w, 27]); translate([laptop_d - 1, 0, 0]) cube([1, laptop_w, 18.5]); }
        }
        color("#e5484d") translate([0, 0, 0]) difference() { footprint(2); translate([0, 0, -1]) offset(delta = -1.2) footprint(4); }
        color("#ffc53d") for (p = [[60, 9], [80, 11], [100, 11], [125, 9], [150, 15], [178, 13]])
            translate([p[0], -0.6, 6]) cube([p[1], 1, 7]);
        color("#2b2f38", 0.5) translate([hinge_x, 0, 27]) rotate([0, -lid, 0]) cube([laptop_d - hinge_x, laptop_w, 5]);
    }
    color("#3a3f47") for (x = [30, laptop_d - 30]) translate([x - 6, 30, z]) cube([12, laptop_w - 60, 2]);
}

module paper() color("#f6f3ea") translate([95, (laptop_w - 297) / 2, 0]) cube([210, 297, 20]);

module cables() color("#c23b3b") {
    for (x = [70, 105, 156]) hull() { translate([x, -4, deck + 11]) sphere(3); translate([x, -20, deck + 6]) sphere(3); }
    for (x = [70, 105, 156]) hull() { translate([x, -20, deck + 6]) sphere(3); translate([x, -24, 6]) sphere(3); }
    hull() { translate([156, -24, 6]) sphere(3); translate([end_seg_mid[0], -24, 6]) sphere(3); }
    hull() { translate([end_seg_mid[0], -24, 8]) sphere(3); translate([end_seg_mid[0], laptop_w + 24, 8]) sphere(3); }
    hull() { translate([end_seg_mid[0], laptop_w + 24, 8]) sphere(3); translate([end_seg_mid[0] - 40, laptop_w + 24, 26]) sphere(3); }
}

if (view == "hero" || view == "lid") { riser(); color("#5b9bd5") organizers(); laptop(); cables(); }
if (view == "docs") { riser(); laptop(); paper(); }
if (view == "vertical") {
    vertical();
    translate([-12.75, -(laptop_w - 2 * cradle_w - span / 2) / 2, slot_z + 1]) rotate([0, -90, 0]) translate([0, 0, -25.5]) mirror([0, 0, 0])
        color("#202329", 0.6) cube([laptop_d, laptop_w - 0, 25.5]);
}
if (view == "exploded") {
    sp = 1.0;
    layout_parts = [];
    translate([0, 0, 0]) {
        for (i = [0 : 2]) translate([i * 110, 0, 0]) color("#d8d4cc") segment();
        for (i = [0 : 2]) translate([i * 110, 0, 25]) color("#f08a3c") rail_cap(i != 1);
        translate([340, 0, 0]) color("#f08a3c") end_cap();
        translate([-50, 0, 0]) color("#f08a3c") end_cap();
        translate([0, 120, 0]) color("#7c8794") rotate(-90) spine();
        translate([0, 190, 0]) color("#7c8794") rotate(-90) bar();
        translate([200, 120, 0]) color("#7c8794") for (i = [0 : 3]) translate([i * 22, 0, 0]) key(k_wall, wall_top - 0.4);
        translate([300, 120, 0]) color("#7c8794") for (i = [0 : 3]) translate([i * 14, 0, 0]) key(k_tray, tray_h - 0.4);
        translate([0, -120, 0]) color("#5b9bd5") {
            pen_cup(); translate([80, 0, 0]) phone_stand(); translate([180, 0, 0]) catch_tray();
            translate([330, 0, 0]) cable_dock(); translate([430, 0, 0]) headphone_hook();
        }
    }
}
if (view == "tests") {
    color("#d8d4cc") fit_coupon();
    color("#7c8794") translate([0, 50, 0]) { key(k_wall, 16); translate([24, 0, 0]) key(k_tray, 16); translate([44, 0, 0]) key(k_floor, 16);
        translate([72, 0, 0]) key(k_bar, 16); translate([100, 0, 0]) test_tail(); }
    color("#f08a3c") translate([140, 0, 0]) end_cap();
    color("#f08a3c") translate([0, 90, -wall_top + 4]) translate([0, -cap_y0, 0]) rail_cap(true);
}
