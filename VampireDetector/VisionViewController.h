//
//  VisionViewController.h
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "ApplicationControl.h"
@import GLKit;
@import AVFoundation;
@import UIKit;

@interface VisionViewController : GLKViewController
<AVCaptureVideoDataOutputSampleBufferDelegate>{
    
    AVCaptureSession *captureSession;
    CIContext *coreImageContext;
    CGContextRef ctx;
    GLuint renderBuffer;
    GLKView *cameraView;
    EAGLContext *eaglContext;
    ApplicationControl *ac;
    CIDetector *faceDetector;
    dispatch_queue_t detectionBackgroundQueue;
    CIFaceFeature *face;
    CALayer *recticleLayer;
    CGRect displayBounds;
    CGColorSpaceRef colorSpace; 
    int frameNumber;
    
}

-(CIImage *)processFrame:(CIImage *)image;


@end
