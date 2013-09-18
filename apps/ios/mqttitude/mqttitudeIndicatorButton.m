//
//  mqttitudeIndicatorButton.m
//  mqttitude
//
//  Created by Christoph Krey on 11.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeIndicatorButton.h"

#define LINE_WIDTH 4.0
@implementation mqttitudeIndicatorButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    
    [circle addClip];
    
    [self.color setFill];
    UIRectFill(self.bounds);
    
    [[UIColor blackColor] setStroke];
    circle.lineWidth = LINE_WIDTH;
    [circle stroke];
}

@end
