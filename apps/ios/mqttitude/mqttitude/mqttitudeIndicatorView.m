//
//  mqttitudeIndicatorView.m
//  mqttitude
//
//  Created by Christoph Krey on 23.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeIndicatorView.h"

@implementation mqttitudeIndicatorView

- (void)drawRect:(CGRect)rect
{    
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    
    [circle addClip];
        
    [self.color setFill];
    UIRectFill(self.bounds);
    
    [[UIColor blackColor] setStroke];
    circle.lineWidth = 5.0;
    [circle stroke];
}
@end
