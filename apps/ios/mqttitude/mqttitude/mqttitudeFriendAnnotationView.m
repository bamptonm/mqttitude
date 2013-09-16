//
//  mqttitudeFriendAnnotationView.m
//  mqttitude
//
//  Created by Christoph Krey on 15.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeFriendAnnotationView.h"

@implementation mqttitudeFriendAnnotationView

#define IMAGE_SIZE 40.0
#define STROKE_WIDTH 2.0
#define IMAGE_ALPHA 0.66
#define OLD_TIME -12*60*60

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
        CGRect rect;
        rect.origin.x = 0;
        rect.origin.y = 0;
        rect.size.width = IMAGE_SIZE;
        rect.size.height = IMAGE_SIZE;
        self.frame = rect;
    }
    return self;
}

- (void)setPersonImage:(UIImage *)image
{
        _personImage = [UIImage imageWithCGImage:image.CGImage
                                               scale:(MAX(image.size.width, image.size.height) / IMAGE_SIZE)
                                         orientation:UIImageOrientationUp];
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:rect];
    
    [circle addClip];
    
    NSDate *timestamp;
    
    if ([self.annotation respondsToSelector:@selector(timeStamp)]) {
        timestamp = [self.annotation performSelector:@selector(timeStamp)];
    }
    [self.personImage drawAtPoint:rect.origin blendMode:kCGBlendModeNormal alpha:IMAGE_ALPHA];
    
    if (timestamp) {
        if ([timestamp compare:[NSDate dateWithTimeIntervalSinceNow:OLD_TIME]] == NSOrderedAscending) {
            [[UIColor redColor] setStroke];
        } else {
            [[UIColor greenColor] setStroke];
        }
    } else {
        [[UIColor blackColor] setStroke];
    }
    
    [circle setLineWidth:STROKE_WIDTH];
    [circle stroke];
}


@end
