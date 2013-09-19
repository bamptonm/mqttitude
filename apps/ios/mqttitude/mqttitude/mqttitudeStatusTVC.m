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



@interface mqttitudeStatusTVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIurl;
@property (weak, nonatomic) IBOutlet UITextField *UIclosed;
@property (weak, nonatomic) IBOutlet UITextField *UIconnected;
@property (weak, nonatomic) IBOutlet UITextField *UIerror;
@property (weak, nonatomic) IBOutlet UITextView *UIerrorCode;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectionButton;

@end

@implementation mqttitudeStatusTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    switch (self.connection.state) {
        case state_connected:
            self.connectionButton.tintColor = [UIColor greenColor];
            break;
        case state_error:
            self.connectionButton.tintColor = [UIColor redColor];
            break;
        case state_connecting:
        case state_closing:
            self.connectionButton.tintColor = [UIColor yellowColor];
            break;
        case state_starting:
        default:
            self.connectionButton.tintColor = [UIColor blueColor];
            break;
    }
    
    self.UIurl.text = self.connection.url;
    
    self.UIconnected.text = ([self.connection.lastConnected compare:self.connection.lastClosed] == NSOrderedDescending) ? [NSDateFormatter localizedStringFromDate:self.connection.lastConnected
                                                                                                                                                         dateStyle:NSDateFormatterShortStyle
                                                                                                                                                         timeStyle:NSDateFormatterMediumStyle] : @"";
    self.UIclosed.text = ([self.connection.lastClosed compare:self.connection.lastConnected] == NSOrderedDescending) ? [NSDateFormatter localizedStringFromDate:self.connection.lastClosed
                                                                                                                                                      dateStyle:NSDateFormatterShortStyle
                                                                                                                                                      timeStyle:NSDateFormatterMediumStyle] : @"";
    self.UIerror.text = ([self.connection.lastError compare:self.connection.lastConnected] == NSOrderedDescending) ?[NSDateFormatter localizedStringFromDate:self.connection.lastError
                                                                                                                                                    dateStyle:NSDateFormatterShortStyle
                                                                                                                                                    timeStyle:NSDateFormatterMediumStyle] : @"";
    
    self.UIerrorCode.text = ([self.connection.lastError compare:self.connection.lastConnected] == NSOrderedDescending) ? [NSString stringWithFormat:@"%@ %d %@",
                                                                                                                          self.connection.lastErrorCode.domain,
                                                                                                                          self.connection.lastErrorCode.code,
                                                                                                                          self.connection.lastErrorCode.localizedDescription ?
                                                                                                                          self.connection.lastErrorCode.localizedDescription : @""] : @"";
    
    
}

@end
