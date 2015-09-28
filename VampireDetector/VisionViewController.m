//
//  VisionViewController.m
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "VisionViewController.h"

@implementation VisionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"VisionViewController viewDidLoad()");
    frameNumber = 0;
    
    ac = [ApplicationControl getInstance];
    
    detectionBackgroundQueue = dispatch_queue_create("com.apollonarius.vampiredetector.facedetection", DISPATCH_QUEUE_SERIAL);
    
    displayBounds = CGRectMake(0,0,ac->displayBounds[2],ac->displayBounds[3]);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSLog(@"AAA");
    faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                    context:nil options:[NSDictionary
                    dictionaryWithObject:CIDetectorAccuracyHigh
                    forKey:CIDetectorAccuracy]];
    
    NSLog(@"BBB");
    eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    coreImageContext = [CIContext contextWithEAGLContext:eaglContext
                                options: @{kCIContextWorkingColorSpace:[NSNull null]} ];
    NSLog(@"one");
    cameraView = (GLKView *)[self.view viewWithTag:502];
    cameraView.context = eaglContext;
    cameraView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    NSLog(@"two");
    [EAGLContext setCurrentContext:eaglContext];
    
    ctx = CGBitmapContextCreate(NULL,
                                1280, //cameraView.bounds.size.width,
                                720, //cameraView.bounds.size.height,
                                8,
                                0,
                                colorSpace,
                                (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    
    captureSession = [AVCaptureSession new];
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
   // this doesn't seem to work, so mysterious
    [videoDevice lockForConfiguration:nil];
    videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 15);
    videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15);
    [videoDevice unlockForConfiguration];

    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if (!error) {
        if ([captureSession canAddInput:videoInput]){
            [captureSession addInput:videoInput];
            NSLog(@"Added video input");
        }else{
            NSLog(@"Failed to add video input");
        }
    }else{
        NSLog(@"Error %@", error);
    }
    
  
    [captureSession beginConfiguration];
    [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    
    
    AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *newSettings =@{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    videoOutput.videoSettings = newSettings;
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];

    dispatch_queue_t videoOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoOutputQueue];
    
    if ( [captureSession canAddOutput:videoOutput] ){
        [captureSession addOutput:videoOutput];
         NSLog(@"NO Video data output");
    }else{
        NSLog(@"YES Video data output");
    }
    
    [captureSession commitConfiguration];
    [captureSession startRunning];

    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    

   // NSLog(@"***START processing frame %d", frameNumber);
    
    
    if ([connection isVideoOrientationSupported]){
        [connection setVideoOrientation: AVCaptureVideoOrientationLandscapeLeft];
    }
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    image = [self processFrame:image];
    
    [coreImageContext drawImage:image inRect:displayBounds fromRect:[image extent] ];
    
    frameNumber++;
}

-(void)viewDidUnload{
    [super viewDidUnload];
    
    NSLog(@"Unloading camera view");
    
    [captureSession stopRunning];
    captureSession = nil;
    
    if([EAGLContext currentContext] == eaglContext){
        [EAGLContext setCurrentContext:nil];
    }
    
    eaglContext = nil;
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CIImage *)processFrame:(CIImage *)image{
    
    // detect faces
    
    if(!ac->detectionActive){
        
        NSLog(@"Attempting face detection!!!");
    
        dispatch_async(detectionBackgroundQueue, ^(void) {

            ac->detectionActive = true;
    
            NSArray *features = [faceDetector featuresInImage:image];
            int featureCount = [features count];
    
            if(featureCount>0){
        
                NSLog(@"Face Detected!!!");
        
                ac->detected = true;
                ac->detectionState++;
                
                CIFaceFeature *feature = [features objectAtIndex:0];

                if(feature.hasLeftEyePosition && feature.hasRightEyePosition){
                    float xlength = fabsf(feature.leftEyePosition.x - feature.rightEyePosition.x);
                    float ylength = fabsf(feature.leftEyePosition.y - feature.rightEyePosition.y);
                
                    ac->dist = sqrt(pow(xlength,2.0) + pow(ylength,2.0));
                        
                    ac->facexCenter = feature.leftEyePosition.x + xlength/2;
                    ac->faceyCenter = feature.leftEyePosition.y + ylength/2;
                        
                    face = feature;
                
                    NSLog(@"Good Face!!!");
                }

            }else{
                NSLog(@"No Face Detected!!!");
                ac->detected = false;
                ac->detectionState--;
            }
            
            ac->detectionActive = false;
            
            ac->lastx = ac->swidth/2;
            ac->lasty = ac->sheight/2;
            
            ac->curx = ((ac->dx - ac->lastx) * (-.05f)) + ac->dx;
            ac->cury = ((ac->dy - ac->lasty) * (-.05f)) + ac->dy;
            
            if((ac->dx - ac->lastx)<=-focusRate){
                ac->curx = ac->lastx - focusRate;
            }else if(ac->dx - ac->lastx>=focusRate){
                ac->curx = ac->lastx + focusRate;
            }else{
                ac->curx = ac->dx;
            }
            
            if((ac->dy - ac->lasty)<=-focusRate){
                ac->cury = ac->lasty - focusRate;
            }else if(ac->dy - ac->lasty>=focusRate){
                ac->cury = ac->lasty + focusRate;
            }else{
                ac->cury = ac->dy;
            }
            
            if (ac->detectionState > 8) {
                ac->detectionState = 8;
            }else if(ac->detectionState < 0){
                ac->detectionState = 0;
            }
        });
    }
    // apply initial filters
    
    image = [CIFilter filterWithName:@"CIFalseColor" keysAndValues: kCIInputImageKey, image, @"inputColor0",
             [CIColor colorWithRed:0.0 green:0.0 blue:0.0], @"inputColor1",
             [CIColor colorWithRed:1.0 green:0.0 blue:0.0], nil].outputImage;
    
    if (ac->detected && ac->detectionState>0) {
        
        CGImageRef imageRef = [coreImageContext createCGImage:image fromRect:[image extent]];
        
        CGContextDrawImage(ctx, image.extent, imageRef);
        
        CGContextSetLineWidth(ctx, 5.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);

        CGContextAddArc(ctx, ac->facexCenter, ac->faceyCenter, (ac->dist * 2.5), 0, 359, 0);
        CGContextStrokePath(ctx);
        
       
        //textPaint.setTextSize(ac.dist);
        if(fabsf(ac->dx - ac->curx)<(2*focusRate) && fabsf(ac->dy - ac->cury)<(2*focusRate)) {
            // because there is no such thing as vampires... right?
            //c.drawText("HUMAN", (curx - ac.dist), (cury + (ac.dist * 4)), textPaint);
            
            //UIFont *font = [UIFont fontWithName: @"Courier" size: kCellFontSize];
            
            UIFont *font = [UIFont systemFontOfSize:8.0];
            
            NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys: font, NSFontAttributeName,
                                        nil];
            
            CGRect speciesLabel = CGRectMake((ac->curx - ac->dist), (ac->cury + (ac->dist * 3.5)),
                                             (ac->curx + ac->dist), (ac->cury + (ac->dist * 4)));
            
            [@"HUMAN" drawInRect: speciesLabel withAttributes: dictionary];
            NSLog(@"Supposed to draw text here!");
        }
        
        
        ac->lastx = ac->curx;
        ac->lasty = ac->cury;
        
        CGImageRef imageRefFinal = CGBitmapContextCreateImage(ctx);
        image = [CIImage imageWithCGImage:imageRefFinal];
        
        CGImageRelease(imageRef);
        CGImageRelease(imageRefFinal);
        
    }
    ac->displayState = 1;
    
    return image;
    
}

@end
