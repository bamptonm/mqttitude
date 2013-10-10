//
//  mqttitudeEditLocationTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 01.10.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeEditLocationTVC.h"
#import "Friend+Create.h"

@interface mqttitudeEditLocationTVC ()
@property (weak, nonatomic) IBOutlet UITextField *UItimestamp;
@property (weak, nonatomic) IBOutlet UITextField *UIcoordinate;
@property (weak, nonatomic) IBOutlet UITextView *UIplace;
@property (weak, nonatomic) IBOutlet UITextField *UIremark;

@end

@implementation mqttitudeEditLocationTVC

- (void)setLocation:(Location *)location
{
    _location = location;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [self.location.belongsTo name] ? [self.location.belongsTo name] : self.location.belongsTo.topic;
    
    self.UIcoordinate.text = [NSString stringWithFormat:@"%f,%f", [self.location.latitude doubleValue] , [self.location.longitude doubleValue]];
    self.UItimestamp.text = [NSDateFormatter localizedStringFromDate:self.location.timestamp
                                                           dateStyle:NSDateFormatterShortStyle
                                                           timeStyle:NSDateFormatterMediumStyle];
    self.UIplace.text = self.location.placemark;
    self.UIremark.text = self.location.remark;
}

- (IBAction)remarkchanged:(UITextField *)sender {
    self.location.remark = sender.text;
}

@end
