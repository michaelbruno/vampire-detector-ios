//
//  RecticleUIView.m
//  VampireDetector
//
//  Created by Michael Bruno on 9/18/15.
//  Copyright (c) 2015 Apollonarius. All rights reserved.
//

#import "RecticleUIView.h"

@implementation RecticleUIView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
       // ac = [ApplicationControl getInstance];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    NSLog(@"DRAW RECT IST JEZT");
    
    ac = [ApplicationControl getInstance];
    
    [super drawRect:rect];
    
    if(ac->detected && ac->detectionState>0){
        
        NSLog(@"JA JA JA");
    
        CGContextRef ctx = UIGraphicsGetCurrentContext();
    
        CGContextSetLineWidth(ctx, 5.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        
        NSLog(@"X:%f Y:%f", ac->facexCenter, ac->faceyCenter);
    
        CGContextAddArc(ctx, ac->facexCenter, (ac->sheight - ac->faceyCenter), (ac->dist * 3), 0, 359, 0);
        CGContextStrokePath(ctx);
        
        // more stuff
        
        CGContextSetStrokeColorWithColor(ctx, [UIColor blueColor].CGColor);
        CGContextAddArc(ctx, 0, 0, 10, 0, 359, 0);
        CGContextStrokePath(ctx);
        
        CGContextSetStrokeColorWithColor(ctx, [UIColor blueColor].CGColor);
        CGContextAddArc(ctx, 100, 100, 10, 0, 359, 0);
        CGContextStrokePath(ctx);
        
        CGContextSetStrokeColorWithColor(ctx, [UIColor blueColor].CGColor);
        CGContextAddArc(ctx, 500, 500, 10, 0, 359, 0);
        CGContextStrokePath(ctx);
    
    //textPaint.setTextSize(ac.dist);
        if(fabsf(ac->dx - ac->curx)<(2*FOCUSRATE) && fabsf(ac->dy - ac->cury)<(2*FOCUSRATE)) {
        // because there is no such thing as vampires... right?
        //c.drawText("HUMAN", (curx - ac.dist), (cury + (ac.dist * 4)), textPaint);
            NSLog(@"Supposed to draw text here!");
        }
    
    //CGImageRef imageRefFinal = CGBitmapContextCreateImage(ctx);
    
    }else{
        NSLog(@"NEIN NEIN NEIN");
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(ctx, 5.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor blueColor].CGColor);
        CGContextAddArc(ctx, 100, 100, 10, 0, 359, 0);
        CGContextStrokePath(ctx);
    }
}

//- (void)setNeedsDisplay {
//    [super setNeedsDisplay];
//    NSLog(@"WHAT GIVES MAN< I JUST dONT UNDERSTAND!!!!");
   // [self.layer setNeedsDisplay];
//}


@end