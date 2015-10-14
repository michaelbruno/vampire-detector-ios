//
//  VisionActivityViewController.h
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "ApplicationControl.h"
@import AVFoundation;
@import UIKit;

@interface VisionActivityViewController : UIViewController{
    
    ApplicationControl *ac;
    bool continueAnimation;
    
}


-(IBAction)lightModeClicked:(UIButton *)sender;

-(IBAction)colorModeClicked:(UIButton *)sender;

-(IBAction)effectModeClicked:(UIButton *)sender;

-(void)infiniteSpin;

@end
