//
//  MainActivityViewController.m
//  VampireDetector
//
//  Created by Michael Bruno on 8/14/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "MainActivityViewController.h"

@interface MainActivityViewController ()

@end

@implementation MainActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //make button round to match android version
    
    UIButton *startButton = (UIButton *)[self.view viewWithTag:256];
    startButton.layer.cornerRadius = self.view.frame.size.height * 0.15 * 0.5;
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    UIImageView *wheelImage = (UIImageView *)[self.view viewWithTag:257];
    CGAffineTransform spin = CGAffineTransformRotate(wheelImage.transform, M_PI_2);
    
    [UIView animateWithDuration:10.0f delay:0.0 options:UIViewAnimationOptionCurveLinear  | UIViewAnimationOptionRepeat
                     animations:^{
                         wheelImage.transform = spin;
                     }
                     completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
