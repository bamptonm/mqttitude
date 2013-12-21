//
//  mqttitudeAlertView.h
//  mqttitude
//
//  Created by Christoph Krey on 20.12.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mqttitudeAlertView : NSObject
+ (void)alert:(NSString *)title message:(NSString *)message;
+ (void)alert:(NSString *)title message:(NSString *)message dismissAfter:(NSTimeInterval)interval;
@end
