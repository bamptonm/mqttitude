//
//  mqttitudeStatusTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 11.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeStatusTVC.h"
#import <errno.h>
#import <CoreFoundation/CFError.h>
#import <mach/mach_error.h>
#import <Security/SecureTransport.h>
#import "mqttitudeAppDelegate.h"


@interface mqttitudeStatusTVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIurl;
@property (weak, nonatomic) IBOutlet UITextView *UIerrorCode;
@property (weak, nonatomic) IBOutlet UITextField *UIeffectiveTopic;
@property (weak, nonatomic) IBOutlet UITextField *UIeffectiveClientId;
@property (weak, nonatomic) IBOutlet UITextField *UIeffectiveWillTopic;

@end

@implementation mqttitudeStatusTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.UIurl.text = self.connection.url;
    
    self.UIerrorCode.text = [NSString stringWithFormat:@"%@ %d %@",
                             self.connection.lastErrorCode.domain,
                             self.connection.lastErrorCode.code,
                             self.connection.lastErrorCode.localizedDescription ?
                             self.connection.lastErrorCode.localizedDescription : @""];

    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    self.UIeffectiveClientId.text = [delegate theClientId];
    self.UIeffectiveTopic.text = [delegate theGeneralTopic];
    self.UIeffectiveWillTopic.text = [delegate theWillTopic];
}

@end
