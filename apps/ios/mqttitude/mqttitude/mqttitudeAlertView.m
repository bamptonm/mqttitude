//
//  mqttitudeAlertView.m
//  mqttitude
//
//  Created by Christoph Krey on 20.12.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeAlertView.h"

#define DISMISS_AFTER 0.5

@implementation mqttitudeAlertView

+ (void)alert:(NSString *)title message:(NSString *)message
{
    [mqttitudeAlertView alert:title message:message dismissAfter:0];
}

+ (void)alert:(NSString *)title message:(NSString *)message dismissAfter:(NSTimeInterval)interval
{
#ifdef DEBUG
    NSLog(@"App alert %@/%@ (%f)", title, message, interval);
#endif
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:interval ? nil : @"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        if (interval) {
            [mqttitudeAlertView performSelector:@selector(dismissAfterDelay:) withObject:alertView afterDelay:interval];
        }
    }
}

+ (void)dismissAfterDelay:(UIAlertView *)alertView
{
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

@end
