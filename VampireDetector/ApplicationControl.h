//
//  ApplicationControl.h
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

@import UIKit;


extern const float FOCUSRATE;
extern const float VIDEOW;
extern const float VIDEOH;

@interface ApplicationControl : NSObject {
    
//@public int *pixels;
//@public int *detectionPixels;
@public int cwidth;;
@public int cheight;
@public float swidth;
@public float sheight;
@public int colorMode;
@public bool effectMode;
@public int displayState;
@public int detectionState;
@public bool lightOn;
@public bool lightAvailable;
@public int bufferSize;
@public float dx;
@public float dy;
@public float curx;
@public float cury;
@public float lastx;
@public float lasty;
@public float dist;
@public float facexCenter;
@public float faceyCenter;
@public bool detected;
@public bool detectionActive;
@public float FDCLIP_RIGHT; // = 0.4f;
@public float FDCLIP_LEFT; // = 0.25f;
@public float FDCLIP_TOP; // = 0.20f;
@public float FDCLIP_BOTTOM; // = 0.20f;
@public int bounds[4];
@public float multi;
@public float displayBounds[4];
//@public CGRect displayBounds;
    
}


- (id)init;
+ (ApplicationControl *)getInstance;

@end


