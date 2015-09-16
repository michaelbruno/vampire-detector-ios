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
    
    NSLog(@"VisionActivityViewController viewDidLoad()");
    
    ac = [ApplicationControl getInstance];
    
}


-(IBAction)lightModeClicked:(UIButton *)sender{
    
    if(ac->lightOn){
        ac->lightOn = false;
    }else{
        ac->lightOn = true;
    }
    
    NSLog(@"lightModeClicked");
    
}


-(IBAction)colorModeClicked:(UIButton *)sender{
    
    NSLog(@"colorModeClicked");
    
}


-(IBAction)effectModeClicked:(UIButton *)sender{
    
    NSLog(@"effectModeClicked");
    
}


-(void)viewDidUnload{
    [super viewDidUnload];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate{
    return NO;
}


/*
 public void lightButtonClick(View v) {
 
 ac.lightOn = ((ToggleButton) v).isChecked();
 processor.resetCamera();
 
 }
 
 
 public void colorModeClick(View v) {
 
 boolean active = ((ToggleButton) v).isChecked();
 
 if (active) {
 ac.colorMode = 2;
 
 } else {
 ac.colorMode = 1;
 }
 processor.resetCamera();
 
 }
 
 public void effectModeClick(View v) {
 
 ac.effectMode = ((ToggleButton) v).isChecked();
 processor.resetCamera();
 
 }
 */
@end