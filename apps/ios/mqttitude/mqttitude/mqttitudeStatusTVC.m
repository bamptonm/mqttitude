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
@property (weak, nonatomic) IBOutlet UITextField *UIeffectiveDeviceId;

@end

@implementation mqttitudeStatusTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [NSString stringWithFormat:@"App Version %@",
                  [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]];

    self.UIurl.text = self.connection.url;
    
    self.UIerrorCode.text = self.connection.lastErrorCode ? [NSString stringWithFormat:@"%@ %d %@",
                                                             self.connection.lastErrorCode.domain,
                                                             self.connection.lastErrorCode.code,
                                                             self.connection.lastErrorCode.localizedDescription ?
                                                             self.connection.lastErrorCode.localizedDescription : @""]
                                                            : @"<no error>";
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    self.UIeffectiveDeviceId.text = [delegate.settings theDeviceId];
    self.UIeffectiveClientId.text = [delegate.settings theClientId];
    self.UIeffectiveTopic.text = [delegate.settings theGeneralTopic];
    self.UIeffectiveWillTopic.text = [delegate.settings theWillTopic];
}

- (IBAction)send:(UIBarButtonItem *)sender
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:[NSString stringWithFormat:@"MQTTitude config %@", self.UIeffectiveClientId.text]];
    
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [picker addAttachmentData:[delegate.settings toData] mimeType:@"application/json"
                     fileName:[NSString stringWithFormat:@"Config-%@.mqtc", self.UIeffectiveClientId.text]];
    
    NSString *emailBody = @"see attached file";
    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:^{
        // done
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:^{
        // done
    }];
}


@end
