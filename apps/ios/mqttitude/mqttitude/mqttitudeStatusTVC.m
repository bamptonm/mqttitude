//
//  mqttitudeStatusTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 11.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeStatusTVC.h"


@interface mqttitudeStatusTVC ()
@property (weak, nonatomic) IBOutlet UITextField *UIurl;
@property (weak, nonatomic) IBOutlet UITextField *UIclosed;
@property (weak, nonatomic) IBOutlet UITextField *UIconnected;
@property (weak, nonatomic) IBOutlet UITextField *UIerror;
@property (weak, nonatomic) IBOutlet UITextField *UIerrorCode;

@end

@implementation mqttitudeStatusTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.UIurl.text = self.connection.url;
    self.UIconnected.text = [NSDateFormatter localizedStringFromDate:self.connection.lastConnected
                                                        dateStyle:NSDateFormatterShortStyle
                                                        timeStyle:NSDateFormatterMediumStyle];
    self.UIclosed.text = [NSDateFormatter localizedStringFromDate:self.connection.lastClosed
                                                        dateStyle:NSDateFormatterShortStyle
                                                        timeStyle:NSDateFormatterMediumStyle];
    self.UIerror.text = [NSDateFormatter localizedStringFromDate:self.connection.lastError
                                                        dateStyle:NSDateFormatterShortStyle
                                                        timeStyle:NSDateFormatterMediumStyle];
    
    switch (self.connection.lastErrorCode) {
        case -4:
            self.UIerrorCode.text = @"can't encode";
            break;
        case -3:
            self.UIerrorCode.text = @"can't decode";
            break;
        case -2:
            self.UIerrorCode.text = @"msg length != 2";
            break;
        case -1:
            self.UIerrorCode.text = @"no CONNACK received";
            break;
        case 0:
            self.UIerrorCode.text = @"ok";
            break;
        case 1:
            self.UIerrorCode.text = @"unacceptable protocol version";
            break;
        case 2:
            self.UIerrorCode.text = @"identifier rejected";
            break;
        case 3:
            self.UIerrorCode.text = @"server unavailable";
            break;
        case 4:
            self.UIerrorCode.text = @"bad user name or password";
            break;
        case 5:
            self.UIerrorCode.text = @"not authorized";
            break;
        default:
            self.UIerrorCode.text = @"reserved for future use";
            break;
    }
}

@end
