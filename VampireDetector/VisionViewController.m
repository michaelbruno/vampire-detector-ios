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
    
    detectionBackgroundQueue = dispatch_queue_create("com.apollonarius.vampiredetector.facedetection", NULL);
    
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
    
    captureSession = [AVCaptureSession new];
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
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
    
    
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    dispatch_queue_t videoOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoOutputQueue];
    
    if ( [captureSession canAddOutput:videoOutput] ){
        [captureSession addOutput:videoOutput];
         NSLog(@"NO Video data output");
    }else{
        NSLog(@"YES Video data output");
    }
    
    [captureSession commitConfiguration];
    
    NSLog(@"AV Capture Session Configured");
    [captureSession startRunning];
    NSLog(@"AV CAaputre Session Running");
    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    

    NSLog(@"***START processing frame %d", frameNumber);
    
    
    if ([connection isVideoOrientationSupported]){
        [connection setVideoOrientation: AVCaptureVideoOrientationLandscapeLeft];
    }
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    /*
    float ox = image.extent.origin.x;
    float oy = image.extent.origin.y;
    
    float oh = image.extent.size.height;
    float ow = image.extent.size.width;
    
    NSLog(@"Image stuff A %f , %f", ox,oy);
    NSLog(@"Image stuff B %f x %f", oh,ow);
    */
  /*
     image = [CIFilter filterWithName:@"CIFalseColor" keysAndValues: kCIInputImageKey, image, @"inputColor0",
     [CIColor colorWithRed:0.0 green:0.2 blue:0.0], @"inputColor1",
     [CIColor colorWithRed:0.0 green:0.0 blue:1.0], nil].outputImage;
    
     CGImageRef completedImage = [self processFrame:image];
     */
    
    
    image = [self processFrame:image];
    
    [coreImageContext drawImage:image inRect:ac->displayBounds fromRect:[image extent] ];
    //[cameraView display];
    
    //[image release];
    //CGContextDrawImage(self.context,cameraView.bounds,completedImage);
    //[self.context presentRenderbuffer:GL_RENDERBUFFER];
    NSLog(@"***END processing frame %d", frameNumber);
    
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
    
    //dispatch_release(detectionBackgroundQueue);
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
        
                for(CIFaceFeature *feature in features){
            
                    if(feature.hasLeftEyePosition && feature.hasRightEyePosition){
                        float xlength = fabsf(feature.leftEyePosition.x - feature.rightEyePosition.x);
                        float ylength = fabsf(feature.leftEyePosition.y - feature.rightEyePosition.y);
                
                        ac->dist = sqrt(pow(xlength,2.0) + pow(ylength,2.0));
                        
                        ac->facexCenter = feature.leftEyePosition.x + xlength/2;
                        ac->faceyCenter = feature.leftEyePosition.y + ylength/2;
                        
                        face = feature;
                
                        NSLog(@"Good Face!!!");
                    }
                }
            }else{
                NSLog(@"No Face Detected!!!");
                ac->detected = false;
                ac->detectionState--;
            }
            
            ac->detectionActive = false;
        
        });
    }
    // apply initial filters
    
    image = [CIFilter filterWithName:@"CIFalseColor" keysAndValues: kCIInputImageKey, image, @"inputColor0",
             [CIColor colorWithRed:0.0 green:0.0 blue:0.0], @"inputColor1",
             [CIColor colorWithRed:1.0 green:0.0 blue:0.0], nil].outputImage;
    
    float lastx = ac->swidth/2;
    float lasty = ac->sheight/2;
    float curx = 0;
    float cury = 0;
    
    if (ac->detectionState > 8) {
        ac->detectionState = 8;
    }
    
    if (ac->detected || ac->detectionState>0) {
        NSLog(@"drawing face");
        
        CGImageRef imageRef = [coreImageContext createCGImage:image fromRect:[image extent]];
        
        /*
        size_t width = CGImageGetWidth(img);
        size_t height = CGImageGetHeight(img);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(img);
        size_t bytesPerRow = CGImageGetBytesPerRow(img);
        */
        // try to smooth detection a little bit
        
        NSLog(@"1. curx: %f cury: %f",curx,cury);
        
        curx = ((ac->dx - lastx) * (-.2f)) + ac->dx;
        cury = ((ac->dy - lasty) * (-.2f)) + ac->dy;
        
        NSLog(@"2. curx: %f cury: %f",curx,cury);
        
        if((ac->dx - lastx)<=-focusRate){
            curx = lastx - focusRate;
        }else if(ac->dx - lastx>=focusRate){
            curx = lastx + focusRate;
        }else{
            curx = ac->dx;
        }
        
        if((ac->dy - lasty)<=-focusRate){
            cury = lasty - focusRate;
        }else if(ac->dy - lasty>=focusRate){
            cury = lasty + focusRate;
        }else{
            cury = ac->dy;
        }
        
        NSLog(@"3. curx: %f cury: %f",curx,cury);
        
        float nd = ac->dist * 3;

        // c.drawCircle(curx, cury, 5.0f, facePaint);
        // c.drawCircle(curx, cury, (ac.dist * 3), facePaint);
        
        
        //CGRect faceRect = face.bounds;
        //NSLog(@"bounds h: %f x w: %f",face.bounds.size.height, face.bounds.size.width);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 CGImageGetBytesPerRow(imageRef),
                                                 colorSpace,
                                                 (CGBitmapInfo)CGImageGetAlphaInfo(imageRef));
        /* oh well...
        CGContextRef ctx = CGBitmapContextCreate(NULL,
                                                 image.extent.size.width,
                                                 image.extent.size.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 CGImageGetBytesPerRow(imageRef),
                                                 colorSpace,
                                                 (CGBitmapInfo)CGImageGetAlphaInfo(imageRef));
        */
        
        CGContextDrawImage(ctx, image.extent, imageRef);
        
        CGContextSetLineWidth(ctx, 5.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
       // CGContextAddRect(ctx, faceRect);
       // CGContextDrawPath(ctx, kCGPathStroke);

        
        CGContextAddArc(ctx, ac->facexCenter, ac->faceyCenter, (ac->dist * 3), 0, 359, 0);
        CGContextStrokePath(ctx);
        
        //textPaint.setTextSize(ac.dist);
        if(fabsf(ac->dx - curx)<(2*focusRate) && fabsf(ac->dy - cury)<(2*focusRate)) {
            // because there is no such thing as vampires... right?
            //c.drawText("HUMAN", (curx - ac.dist), (cury + (ac.dist * 4)), textPaint);
            NSLog(@"Supposed to draw text here!");
        }
        
        lastx = curx;
        lasty = cury;
        
        CGImageRef imageRefFinal = CGBitmapContextCreateImage(ctx);

        image = [CIImage imageWithCGImage:imageRefFinal];
        
        CGImageRelease(imageRef);
        CGImageRelease(imageRefFinal);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(ctx);
   
        
    }else{
         NSLog(@"NOT drawing face");
    }
    ac->displayState = 1;
    

    
    return image;
    
}




@end

