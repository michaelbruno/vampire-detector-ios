//
//  ApplicationControl.m
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "ApplicationControl.h"

@implementation ApplicationControl

#pragma mark Singleton Methods
- (id)init{
    
    self = [super init];
    
    cwidth = 0;
    cheight = 0;
    swidth = 0;
    sheight = 0;
    colorMode = 1;
    effectMode = false;
    displayState = 0;
    detectionState = 0;
    lightOn = false;
    lightAvailable = false;
    detectionActive = false;
    bufferSize = 0;
    dx = 0;
    dy = 0;
    dist = 0;
    detected = 0;
    FDCLIP_RIGHT = 0.4f;
    FDCLIP_LEFT = 0.25f;
    FDCLIP_TOP = 0.20f;
    FDCLIP_BOTTOM = 0.20f;
    
    
    // assume 1280x720 for video
    
    cwidth = 1280;
    cheight = 720;
    
    pixels = malloc((1280 * 720) * sizeof(int));
    detectionPixels = malloc((1280 * 720) * sizeof(int));
    
    //DisplayMetrics metrics = Resources.getSystem().getDisplayMetrics();
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    
    swidth = (int)screenWidth;
    sheight = (int)screenHeight;
    
    float aspect = (float)swidth/(float)sheight;
    multi = (float)sheight/(float)cheight;
    
    NSLog(@"Screen aspect is %f, width:%d x height:%d", aspect, swidth, sheight);
    
    // AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    displayBounds = CGRectMake(0,0,(multi * cwidth),sheight);
    
    //Camera camera = Camera.open();
    //Camera.Parameters params = camera.getParameters();
    
    
    /*
     List<Camera.Size> sizes = params.getSupportedPreviewSizes();
     Camera.Size previewSize = null;
     
     List<Integer> formats = params.getSupportedPreviewFormats();
     for(Integer f:formats){
     Log.d(getClass().getName(), "Prewview Format:"+f+"");
     }
     
     for(int k=0;k<sizes.size();k++){
     
     float ap = (float)sizes.get(k).width/(float)sizes.get(k).height;
     Log.d(getClass().getName(),  + sizes.get(k).width + "x" + sizes.get(k).height + ":" + ap);
     if(swidth > sizes.get(k).width
     && sheight > sizes.get(k).height
     && ap>aspect){
     
     previewSize = sizes.get(k);
     break;
     }
     }
     
     if(previewSize==null){
     previewSize=sizes.get(0);
     }
     
     cwidth = previewSize.width;
     cheight = previewSize.height;
     
     Log.d(getClass().getSimpleName(), "Camera preview set to "+cwidth +"x"+cheight);
     
     
     int previewFormat = ImageFormat.getBitsPerPixel(camera.getParameters().getPreviewFormat());
     int frameSize = cwidth * cheight;
     pixels = new int[frameSize];
     bounds[0] = (int)(cwidth*FDCLIP_LEFT);
     bounds[1] = (int)(cheight*FDCLIP_TOP);
     bounds[2] = (int)(cwidth*(1 - FDCLIP_RIGHT));
     bounds[3] = (int)(cheight*(1 - FDCLIP_BOTTOM));
     
     Log.d(getClass().getSimpleName(),"Detection bounds: " +bounds[0] +"," +bounds[1] +
     " " +bounds[2]+","+bounds[3]);
     detectionPixels = new int[(bounds[2] - bounds[0]) * (bounds[3] - bounds[1])];
     bufferSize = ((frameSize * previewFormat)/8);
     
     camera.release();
     */
    NSLog(@"returning self!");
    
    return self;
}

+ (ApplicationControl *)getInstance{
    static ApplicationControl *applicationControl = nil;
    @synchronized(self) {
        if (applicationControl == nil)
            applicationControl = [[self alloc] init];
    }
    return applicationControl;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    free(pixels);
    free(detectionPixels);
}

@end
