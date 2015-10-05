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
    
    #ifdef DEBUG
    NSLog(@"VisionViewController viewDidLoad()");
    #endif
    
    frameNumber = 0.0;
    detectedFrames = 0.0;
    
    ac = [ApplicationControl getInstance];
    
    detectionBackgroundQueue = dispatch_queue_create("com.apollonarius.vampiredetector.facedetection", DISPATCH_QUEUE_SERIAL);
    
    //displayBounds = CGRectMake(0,0,ac->displayBounds[2],ac->displayBounds[3]);
    
    displayBounds = CGRectMake(0,0,VIDEOW,VIDEOH);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                    context:nil options:[NSDictionary
                    dictionaryWithObject:CIDetectorAccuracyLow
                    forKey:CIDetectorAccuracy]];
    
    eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    coreImageContext = [CIContext contextWithEAGLContext:eaglContext
                                options: @{kCIContextWorkingColorSpace:[NSNull null]} ];

    cameraView = (GLKView *)[self.view viewWithTag:502];
    cameraView.context = eaglContext;
    cameraView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    cameraView.contentMode = UIViewContentModeScaleAspectFit;

    
    #ifdef DEBUG
    NSLog(@"bounds w: %f h: %f",cameraView.bounds.size.width, cameraView.bounds.size.height);
    #endif
    
    [EAGLContext setCurrentContext:eaglContext];
    
    ctx = CGBitmapContextCreate(NULL,
                                VIDEOW,
                                VIDEOH,
                                8,
                                0,
                                colorSpace,
                                (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    
    // init font
    
    displayString = [self createDisplayString:CFSTR("HUMAN")];
    
    captureSession = [AVCaptureSession new];
    
    // make sure back camera is used
    AVCaptureDevice *videoDevice;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            videoDevice = device;
        }
    }
    
    /*
    for ( AVCaptureDeviceFormat *format in [videoDevice formats] ) {
        NSLog(@"description: %@",format.description);
        NSLog(@"%@", format.videoSupportedFrameRateRanges);
     
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            
        }
    }
     */
    
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
        }else{
            #ifdef DEBUG
            NSLog(@"Failed to add video input");
            #endif
        }
    }else{
        #ifdef DEBUG
        NSLog(@"Error %@", error);
        #endif
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
    }else{
        #ifdef DEBUG
        NSLog(@"This might be a problem!");
        #endif
    }
    
    [captureSession commitConfiguration];
    [captureSession startRunning];
 
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
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
    
    #ifdef DEBUG
    NSLog(@"VisionViewController.viewDidUnload()");
    #endif
    
    [captureSession stopRunning];
    captureSession = nil;
    
    if([EAGLContext currentContext] == eaglContext){
        [EAGLContext setCurrentContext:nil];
    }
    
    eaglContext = nil;
    
    CGColorSpaceRelease(colorSpace);
    CFRelease(displayString);
    CGContextRelease(ctx);
    
   
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
 
}

-(CIImage *)processFrame:(CIImage *)image{
    
    // detect faces
    
    if(!ac->detectionActive){
    
        dispatch_async(detectionBackgroundQueue, ^(void) {

            detectedFrames++;
           // float detectionRate = detectedFrames / frameNumber;

            ac->detectionActive = true;
    
            NSArray *features = [faceDetector featuresInImage:image];
            int featureCount = [features count];
    
            if(featureCount>0){
        
                ac->detected = true;
                ac->detectionState++;
                
                CIFaceFeature *feature = [features objectAtIndex:0];

                if(feature.hasLeftEyePosition && feature.hasRightEyePosition){
                    float xlength = fabsf(feature.leftEyePosition.x - feature.rightEyePosition.x);
                    float ylength = fabsf(feature.leftEyePosition.y - feature.rightEyePosition.y);
                
                    float tempdist = sqrt(pow(xlength,2.0) + pow(ylength,2.0));
                    if(tempdist >= (1.2 * ac->dist) || tempdist <= (0.8 * ac->dist)){
                        ac->dist = tempdist;
                    }
                        
                    ac->facexCenter = feature.leftEyePosition.x + xlength/2;
                    ac->faceyCenter = feature.leftEyePosition.y + ylength/2;
                        
                    face = feature;
                }

            }else{
                ac->detected = false;
                ac->detectionState--;
            }
            
            ac->detectionActive = false;
            
            ac->curx = ((ac->facexCenter - ac->lastx) * (-FOCUSRATE)) + ac->facexCenter;
            ac->cury = ((ac->faceyCenter - ac->lasty) * (-FOCUSRATE)) + ac->faceyCenter;
            
            if((ac->facexCenter - ac->lastx)<=-FOCUSRATE){
                ac->curx = ac->lastx - FOCUSRATE;
            }else if(ac->facexCenter - ac->lastx>=FOCUSRATE){
                ac->curx = ac->lastx + FOCUSRATE;
            }else{
                ac->curx = ac->facexCenter;
            }
            
            if((ac->faceyCenter - ac->lasty)<=-FOCUSRATE){
                ac->cury = ac->lasty - FOCUSRATE;
            }else if(ac->faceyCenter - ac->lasty>=FOCUSRATE){
                ac->cury = ac->lasty + FOCUSRATE;
            }else{
                ac->cury = ac->faceyCenter;
            }
            
            if (ac->detectionState > 60) {
                ac->detectionState = 60;
            }else if(ac->detectionState < 0){
                ac->detectionState = 0;
            }
            NSLog(@"x: %f y: %f", ac->curx, ac->cury);
        });
    }
    // apply initial filters
    
    if(ac->effectMode){
        image = [CIFilter filterWithName:@"CIColorInvert" keysAndValues:@"inputImage", image, nil].outputImage;
    }
    
    float rc = 1.0;
    float gc = 0.0;
    if(ac->colorMode == 2){
        rc = 0.0;
        gc = 1.0;
    }
    
    image = [CIFilter filterWithName:@"CIFalseColor" keysAndValues: kCIInputImageKey, image, @"inputColor0",
             [CIColor colorWithRed:0.0 green:0.0 blue:0.0], @"inputColor1",
             [CIColor colorWithRed:rc green:gc blue:0.0], nil].outputImage;
    
    
    if (ac->detected && ac->detectionState>20) {
        
        CGImageRef imageRef = [coreImageContext createCGImage:image fromRect:[image extent]];
        
        CGContextDrawImage(ctx, image.extent, imageRef);
        
        CGContextSetLineWidth(ctx, 5.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);

        //CGContextAddArc(ctx, ac->facexCenter, ac->faceyCenter, (ac->dist * 2.5), 0, 359, 0);
        CGContextAddArc(ctx, ac->curx, ac->cury, (ac->dist * 2.5), 0, 359, 0);
        
        CGContextStrokePath(ctx);
        
        // draw label
        UILabel *speciesLabel = (UILabel *)[self.parentViewController.view viewWithTag:320];
        
        if([self shouldDisplayLabel]) {
            // because there is no such thing as vampires... right?

            /*
            CTLineRef line = CTLineCreateWithAttributedString(displayString);
            CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
            
            CGContextSetTextPosition(ctx, ((1280.0 * 0.7)/2.0), (720.0/2.0));
            //CGContextSetTextPosition(ctx, (ac->facexCenter - (ac->dist * 1.5)), (ac->faceyCenter + (ac->dist * 0.5)));
            CTLineDraw(line, ctx);
            
            CFRelease(line);
             */
            
            
            //speciesLabel.text = @"HUMAN";
            
            //[speciesLabel performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
            
            if([speciesLabel.text isEqualToString:@""]){
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [speciesLabel setAlpha:1.0];
                    [speciesLabel setText:@"HUMAN"];
                    
                    [UIView animateWithDuration:3.0f delay:0.0 options:UIViewAnimationOptionCurveLinear
                                     animations:^{
                                         speciesLabel.alpha = 0.0;
                                     }
                                     completion:nil];
                    
                });
            }

            #ifdef DEBUG
            NSLog(@"text should appear");
            #endif
            
        }else if([speciesLabel.text isEqualToString:@"HUMAN"]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [speciesLabel setAlpha:1.0];
                [speciesLabel setText:@""];
            });
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

/*
 *   Ensure face is in center of view before displaying recticle
 */
-(BOOL)shouldDisplayLabel{
    
    BOOL display = NO;
    
    if(ac->detectionState>=55){
        
        //float xbound = VIDEOW * 0.3;
        //float ybound = VIDEOH * 0.2;
        
        if((ac->faceyCenter > 140) && (ac->faceyCenter < 580)){
            
            if((ac->facexCenter > 228) && (ac->facexCenter < 668)){
                
                if(ac->dist < 400 && fabs(ac->curx - ac->facexCenter)<10 && fabs(ac->cury - ac->faceyCenter)<10){
                    display = YES;
                }
            }
        }
    }
    
    return display;
}

-(CFAttributedStringRef)createDisplayString:(CFStringRef)inputString{
    
    NSDictionary *fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"Enochian", (NSString *)kCTFontFamilyNameAttribute,
                               @"Regular", (NSString *)kCTFontStyleNameAttribute,
                               [NSNumber numberWithFloat:40.0],
                               (NSString *)kCTFontSizeAttribute,
                               nil];
    
    CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttrs);
    CTFontRef fontRef = CTFontCreateWithFontDescriptor(fontDescriptor, 0.0, NULL);
    CFRelease(fontDescriptor);
    
    CFStringRef keys[] = { kCTFontAttributeName, kCTForegroundColorAttributeName };
    CFTypeRef values[] = { fontRef, [UIColor whiteColor].CGColor};
    
    CFDictionaryRef textAttrs =
    CFDictionaryCreate(kCFAllocatorDefault, (const void**)&keys,
                       (const void**)&values, sizeof(keys) / sizeof(keys[0]),
                       &kCFTypeDictionaryKeyCallBacks,
                       &kCFTypeDictionaryValueCallBacks);
    
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, inputString, textAttrs);
    
    CFRelease(fontRef);
    
    return attrString;
}

@end
