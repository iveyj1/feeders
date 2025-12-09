/*
Author: Michael

2017/10/28

*/

/* [basic parameters] */

//How wide is the tape?
tapeWidthNom=8; // [8, 12, 16, 24, 36, 48, 72]
//Optimize for Plastic or Paper tape? Plastic tapes fit in Paper, but not reverse. Plastic tapes may be too loose in paper feeder.
tapeHeight=0.9; // [0.9:paper,0.3:plastic]
//How many feeder to print ganged
numberOfFeeders=6; // [1:1:20]
//Overall length of feeder?
feederLength=120;
//Height of tape's bottom side above bed
tapeLayerHeight=9.5;

bodyHeight=2.5;

spacer = 0.5; // [0:0.5:10]
spacerHeight = bodyHeight*0.8; // [0:8]

//Bank ID: To identify the feeder in OpenPnP unique IDs for each bank are built and embossed into the ganged feeder. -1: no identifier.
bankID=1; //[-1:1:9]
//diameter of pockets on the side to put a magnet in
magnetDiameter=6;
//height of the pocket for the magnet
magnetHeight=0
;


/* [advanced] */

//Extra width for tape slot above tape nominal width
tapeClearance=0.05;     // [-0.5:0.05:0.5]
tapeSupportHoleWidth=2.0;
tapeSupportNonHoleWidth=0.9;

/* [expert] */
//higher values make the left arm stronger
slotWallThickness=0.725;
slotWalls=2*slotWallThickness;
topFinishingLayer=0.3;
tapeGuideUpperOverhang=0.4;
//Thickness of right side wall
springWidth=1.0;

//if two tapeloaded lanes touch each other raise this value a little
springClearance=0.3;
tapeXOffset=-0.10;

slotWidth=tapeWidthNom+tapeClearance;

overallWidth=slotWidth+slotWalls;
overallHeight=tapeLayerHeight+tapeHeight+tapeGuideUpperOverhang+topFinishingLayer;
tapeXcenter=(overallWidth/2+tapeXOffset);

idSize=1.7;
idHeight=bodyHeight-idSize*0.2;

filletRadius=1.2;
    
padLength = 50;
padThickness=0;

pitch = overallWidth+spacer;
echo("Pitch: ", pitch);
//make the feeders
gang_feeder();

module gang_feeder() {
    difference() {
        union() {
            //stack up feeders
            for(i=[0:1:numberOfFeeders-1]) {
                translate([i*(tapeWidthNom+slotWalls+spacer),0,0]) 
                    feeder_body(i);
            }
            if(padThickness>0.05) {
                // Bed adhesion pads
                arrayWidth = (overallWidth+spacer)*numberOfFeeders;
                padWidth = arrayWidth+40;
                translate([arrayWidth/2-padWidth/2, -padLength/2, 0]){ 
                    cube([padWidth, padLength, padThickness]);
                }               
                translate([-padWidth/2+arrayWidth/2, feederLength-padLength/2, 0]){ 
                    cube([padWidth, padLength, padThickness]);
                }
            }        
        }
        
        //magnet pockets
        for(j=[0:1:2]) {
            //magnet pockets right side
            translate([0,j*((feederLength-49)/2)+24.5,0]) {
                translate([(numberOfFeeders)*(tapeWidthNom+slotWalls+spacer),0,0 ]) {
                    magnetic_fixation_pocket();
                }
            }
        }
        
        for(j=[0:1:3]) {
            translate([0,j*((feederLength-15)/3)+7.5,0]) {
                //magnet pockets left side
                rotate([0,0,180])
                    magnetic_fixation_pocket();
            }
        }
        // Slots in ridges to minimize peelup
        for(k=[0:1:5]){
            translate([0, feederLength*(k+1)/6, bodyHeight]){
                cube([100, 0.5, 100]);
            }
        }
    }
}

module feeder_cover() {
    cube(
    
    [2,feederLength,overallHeight]);
}

module extrusion() {
    difference() {
    //main form
    linear_extrude(feederLength) {
        slotRightSide = tapeXcenter+slotWidth/2;
        polyedge(pts=[
            //base
            [0,0],
            [overallWidth + spacer,0],
            [overallWidth + spacer, spacerHeight],
            [overallWidth, spacerHeight],
        
            //right arm way up ("spring", outer part)

            [overallWidth,tapeLayerHeight, filletRadius],
        
            //right arm tape guide
            [overallWidth-springClearance,overallHeight],
            [slotRightSide-tapeGuideUpperOverhang,overallHeight],
            [slotRightSide-tapeGuideUpperOverhang,tapeLayerHeight+tapeHeight+tapeGuideUpperOverhang],
            [slotRightSide,tapeLayerHeight+tapeHeight],
            [slotRightSide,tapeLayerHeight],
            [slotRightSide-tapeSupportHoleWidth,tapeLayerHeight],
            [slotRightSide-tapeSupportHoleWidth,tapeLayerHeight-0.6, filletRadius],
        
            //right arm way down ("spring", inner part)
            [overallWidth-springWidth,tapeLayerHeight-2, filletRadius],
            [overallWidth-springWidth,bodyHeight, filletRadius],
            
            //base (inner part)
            [tapeXcenter-slotWidth/2+tapeSupportNonHoleWidth,bodyHeight, filletRadius],
            
            //left arm up (inner part)
            [tapeXcenter-slotWidth/2+tapeSupportNonHoleWidth,tapeLayerHeight],
            
            //left arm tape guide
            [tapeXcenter-slotWidth/2,tapeLayerHeight],
            [tapeXcenter-slotWidth/2,tapeLayerHeight+tapeHeight],
            [tapeXcenter-slotWidth/2+tapeGuideUpperOverhang,tapeLayerHeight+tapeHeight+tapeGuideUpperOverhang],
            [tapeXcenter-slotWidth/2+tapeGuideUpperOverhang,overallHeight],
            
            //left arm down (outer part)
            [0,overallHeight],
            [0,0]

        ]);
        echo("Slot x positions: left side, center, right side, width",
             tapeXcenter-slotWidth/2,
             tapeXcenter,
             tapeXcenter+slotWidth/2,
             tapeXcenter+slotWidth/2-(tapeXcenter-slotWidth/2));
         }
    }
}    

module feeder_body(feederNo) {
    translate([0,feederLength,0]) {
        rotate([90,0,0]) {
            difference() {
                extrusion();
                //direction of travel while picking with OpenPnP
                if(feederLength>=100) {
                    for (i=[0:1:3]) {
                        translate([slotWalls+3/2+0.5,bodyHeight+0.1,feederLength-25-(i*6)])
                            rotate([90,90,0])
                                linear_extrude(1)
                                    circle(3,$fn=3);
                    }
                }

                //4 identification marks
                translate([slotWalls,idHeight,feederLength-2])
                    rotate([90,90,180])
                        identification_mark(feederNo,"left","top");
                
                translate([slotWalls,idHeight,2])
                    rotate([90,90,180])
                        identification_mark(feederNo,"right","top");
                
                translate([tapeXcenter,idHeight,feederLength-0.9])
                    rotate([0,0,0])
                        identification_mark(feederNo,"center","top");
                
                translate([tapeXcenter,idHeight,0.9])
                    rotate([0,180,0])
                        identification_mark(feederNo,"center","top");
                
                
                
                //reference hole
                translate([tapeXcenter+tapeWidthNom/2-1.75,tapeLayerHeight,feederLength-4])
                    rotate([90,90,0])
                        cylinder(h=0.6,d=1.4,center=false,$fn=20);
                
                //3 registration points (for magnets, bolts or to screw from top)
                //bottom_fixation(feederLength/2);
                bottom_fixation(17);
                bottom_fixation(feederLength-17);
                

            }
        }
    }
}

module identification_mark(feederNo,_halign,_valign) {

    if(bankID!=-1) {
        linear_extrude(height=.91) {
            text( str(bankID, chr(feederNo+65) ),font=":style=Bold", size=idSize, valign=_valign, halign=_halign);
        }
    }
                
}

module magnetic_fixation_pocket() {
    layerBelow=0.25;
    magnetInset=1;
    magnetDiameterOversizedFor3dPrinting=magnetDiameter+0.2;
    
    translate([0,0,layerBelow]) {
            union() {
                translate([-(magnetDiameterOversizedFor3dPrinting)/2-magnetInset,0,0])
                    cylinder(d=magnetDiameterOversizedFor3dPrinting,h=magnetHeight+0.3,$fn=20);
                
                hull() {
                    translate([-(magnetDiameterOversizedFor3dPrinting)/2-magnetInset,0,0])
                        cylinder(d=magnetDiameterOversizedFor3dPrinting-1.4,h=magnetHeight+0.3,$fn=20);
                    translate([0,0,(magnetHeight+0.3)/2])
                        cube([0.1,magnetDiameterOversizedFor3dPrinting+0.4,magnetHeight+0.3],center=true);
                }
                
                translate([-(magnetDiameterOversizedFor3dPrinting)/2-magnetInset,0,0]) {
                    difference() {
                        cylinder(d=magnetDiameterOversizedFor3dPrinting+3,h=magnetHeight+0.3,$fn=20);
                        cylinder(d=magnetDiameterOversizedFor3dPrinting+2,h=magnetHeight+0.3,$fn=20);
                        
                    }
                }
            }
        translate([-(magnetDiameterOversizedFor3dPrinting-magnetInset+1)/2-magnetInset,0,0])
            cube([magnetDiameterOversizedFor3dPrinting,1,1],center=true);
    }
}
            
module bottom_fixation(pos_y) {
    layerForBridging=0.3;
    cutoutbelow=3.5;
    union() {
        translate([tapeXcenter,bodyHeight-1,pos_y])
                rotate([-90,0,0])
                    cylinder(h = 2.1, r=6.0/2, $fn=20);
        
        translate([tapeXcenter,-0.1,pos_y])
                rotate([-90,0,0])
                    cylinder(h = bodyHeight+1, r=3.5/2, $fn=20);
        
        //old pocket below feeder for magnet
        *translate([tapeXcenter,cutoutbelow,pos_y])
                rotate([90,0,0])
                    cylinder(h = 10, r=6.0/2, $fn=20);
        
        //chamfer
        *translate([tapeXcenter,0.3,pos_y])
                rotate([90,0,0])
                    cylinder(h = 0.3, r1=6.0/2, r2=6.3/2, $fn=20);
    }
}

// Copyright (c) 2024 Robert Eisele ( https://raw.org ). All rights reserved.
// Licensed under the MIT license.

// https://raw.org/code/openscad-polygons-with-rounded-corners/


// Example: polyedge([ [x, y, t], ...]);
// The parameter t has the following options:
// = 0: If t is zero (or left out), the edge is becoming a normal sharp edge like in polygon()
// > 0: If t is positive, the edge will get a round corner with radius t
// < 0: If t is negative, the edge will get an inset of length -t from the original edge


function normalize (v) = v / norm(v);
function sgn(a, b) = sign(a[0] * b[1] - a[1] * b[0]);

module polyedge(pts, $fn=$fn) {

    polygon([for (L1 = [
        for (i = [1 : len(pts)])
        let(
            f = $fn == 0 ? 10 : $fn,
            A = pts[(i - 1)],
            B = pts[(i + 0) % len(pts)],
            C = pts[(i + 1) % len(pts)],

            r = B[2],
            S = [B[0], B[1]],
            a = normalize([A[0] - B[0], A[1] - B[1]]),
            b = normalize([C[0] - B[0], C[1] - B[1]]))

             (len(B) == 2 || B[2] == 0)
                ? [ S ]
                : (r < 0 
                    ? [ S - a * r, S - b * r ]
                    : [let(
                        w = r * sqrt(2 / (1 - a * b) - 1),
                        X = a * w,
                        Y = b * w,
                        M = (a + b) * (r / sqrt(1 - pow(a * b, 2))),
                        b1 = atan2(X[1] - M[1], X[0] - M[0]),
                        b2 = atan2(Y[1] - M[1], Y[0] - M[0]),
                        phi = sgn(a, b) * (sgn(a, b) * (b1 - b2) + 360) % 360,
                        segs = ceil(abs(phi) * f / 360)) 
                            for (j = [0 : segs]) 
                                B + M + [
                                    r * cos(b1 - j / segs * phi), 
                                    r * sin(b1 - j / segs * phi)]])]) for (L2 = L1) L2]); 
}

