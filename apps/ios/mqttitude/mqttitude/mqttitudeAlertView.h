//
//  mqttitudeAlertView.h
//  mqttitude
//
//  Created by Christoph Krey on 11.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mqttitudeAlertView : NSObject

- (id)initWithMessage:(NSString *)message dismissAfter:(NSTimeInterval)interval;

@end
