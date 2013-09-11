//
//  mqttitudeAlertView.m
//  mqttitude
//
//  Created by Christoph Krey on 11.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeAlertView.h"

@interface mqttitudeAlertView ()
@property (strong, nonatomic) UIAlertView *alertView;
@end

@implementation mqttitudeAlertView

- (id)initWithMessage:(NSString *)message dismissAfter:(NSTimeInterval)interval
{
    self.alertView = [[UIAlertView alloc] initWithTitle:[NSBundle mainBundle].infoDictionary[@"CFBundleName"]
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
    [self.alertView show];
    
    [self performSelector:@selector(dismissAfterDelay) withObject:nil afterDelay:interval];
    return self;
}

- (void)dismissAfterDelay
{
    [self.alertView dismissWithClickedButtonIndex:0 animated:YES];
}
@end
