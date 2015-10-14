//
//  VisionActivityViewController.m
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "VisionActivityViewController.h"
#import "ApplicationControl.h"


@implementation VisionActivityViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    continueAnimation = true;
    
    #ifdef DEBUG
    NSLog(@"VisionActivityViewController viewDidLoad()");
    #endif
    
    ac = [ApplicationControl getInstance];
    
    /*
    UIImageView *orbiculusRing = (UIImageView *)[self.view viewWithTag:565];
    
    if(orbiculusRing == nil){
        NSLog(@"HO!");
    }
    NSLog(@"height at %f",orbiculusRing.frame.size.height);
    */
    
    UIButton *buttonA = (UIButton *)[self.view viewWithTag:300];
    [buttonA setImage:[UIImage imageNamed:@"button_a_on"] forState:UIControlStateSelected];
    [buttonA setImage:[UIImage imageNamed:@"button_a_off"] forState:UIControlStateNormal];
    
    UIButton *buttonB = (UIButton *)[self.view viewWithTag:301];
    [buttonB setImage:[UIImage imageNamed:@"button_b_on"] forState:UIControlStateSelected];
    [buttonB setImage:[UIImage imageNamed:@"button_b_off"] forState:UIControlStateNormal];
    
    UIButton *buttonC = (UIButton *)[self.view viewWithTag:302];
    [buttonC setImage:[UIImage imageNamed:@"button_c_on"] forState:UIControlStateSelected];
    [buttonC setImage:[UIImage imageNamed:@"button_c_off"] forState:UIControlStateNormal];
    
    UIView *controlPanel = (UIView *)[self.view viewWithTag:310];
    controlPanel.layer.borderColor = [UIColor colorWithRed:200.0f/255.0f
                                                     green:0.0f/255.0f
                                                      blue:0.0f/255.0f
                                                     alpha:1.0f].CGColor;
    controlPanel.layer.borderWidth = 2.0f;
    
    UILabel *speciesLabel = (UILabel *)[self.view viewWithTag:320];
    speciesLabel.text = @"";

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self infiniteSpin];
    
    //UILabel *speciesLabel = (UILabel *)[self.view viewWithTag:320];
    //speciesLabel.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    continueAnimation = false;
    
}

-(void)infiniteSpin{
    
    UIImageView *orbiculusRing = (UIImageView *)[self.view viewWithTag:565];

    CGAffineTransform spin = CGAffineTransformRotate(orbiculusRing.transform, M_PI_2); // (M_PI_2);
    
    [UIView animateWithDuration:5.0f delay:0.0 options:UIViewAnimationOptionCurveLinear  //| UIViewAnimationOptionRepeat
                     animations:^{
                         orbiculusRing.transform = spin;
                     }
                     completion:^(BOOL finished) {
                         if (finished && continueAnimation){// && !CGAffineTransformEqualToTransform(orbiculusRing.transform, CGAffineTransformIdentity)) {
                             [self infiniteSpin];
                         }
                     }];
    
}





-(IBAction)lightModeClicked:(UIButton *)sender{
    
    AVCaptureDevice *videoDevice;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            videoDevice = device;
        }
    }
    
    if (videoDevice.hasTorch){

        [videoDevice lockForConfiguration:nil];

        if (videoDevice.torchActive){
            videoDevice.torchMode = AVCaptureTorchModeOff;
        } else {
            videoDevice.torchMode = AVCaptureTorchModeOn;
        }
        [videoDevice unlockForConfiguration];
    }
    
    sender.selected = !sender.selected;
    
    #ifdef DEBUG
    NSLog(@"lightModeClicked");
    #endif
    
}

-(IBAction)colorModeClicked:(UIButton *)sender{
    
    if(ac->colorMode == 1){
        ac->colorMode = 2;
    }else if(ac->colorMode == 2){
        ac->colorMode = 1;
    }
    
    sender.selected = !sender.selected;
    
    #ifdef DEBUG
    NSLog(@"colorModeClicked");
    #endif
    
}


-(IBAction)effectModeClicked:(UIButton *)sender{
    
    ac->effectMode = !(ac->effectMode);
    
    sender.selected = !sender.selected;

    #ifdef DEBUG
    NSLog(@"effectModeClicked");
    #endif
    
}


-(void)viewDidUnload{
    [super viewDidUnload];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}
@end
