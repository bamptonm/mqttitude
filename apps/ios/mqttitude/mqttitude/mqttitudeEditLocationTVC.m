//
//  mqttitudeEditLocationTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 01.10.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeEditLocationTVC.h"
#import "Friend+Create.h"
#import "mqttitudeAppDelegate.h"

@interface mqttitudeEditLocationTVC ()
@property (weak, nonatomic) IBOutlet UITableViewCell *remarkCell;
@property (weak, nonatomic) IBOutlet UITextField *UItimestamp;
@property (weak, nonatomic) IBOutlet UITextField *UIcoordinate;
@property (weak, nonatomic) IBOutlet UITextView *UIplace;
@property (weak, nonatomic) IBOutlet UITextField *UIremark;
@property (weak, nonatomic) IBOutlet UITextField *UIradius;
@property (weak, nonatomic) IBOutlet UISwitch *UIshare;

@property (nonatomic) BOOL needsUpdate;
@end

@implementation mqttitudeEditLocationTVC

- (void)setLocation:(Location *)location
{
    _location = location;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.location removeObserver:self forKeyPath:@"placemark"];
    if (self.needsUpdate) {
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
        if ([self.location sharedWaypoint]) {
            [delegate sendWayPoint:self.location];
        }
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [self.location nameText];
    
    self.UIcoordinate.text = [self.location coordinateText];
    
    self.UItimestamp.text = [self.location timestampText];

    [self.location addObserver:self forKeyPath:@"placemark" options:NSKeyValueObservingOptionNew context:nil];
    [self.location getReverseGeoCode];
    self.UIplace.text = self.location.placemark;
    
    self.UIremark.text = self.location.remark;
    self.UIradius.text = [self.location radiusText];
    self.UIshare.on = [self.location.share boolValue];
    
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    if (![self.location.automatic boolValue] && [self.location.belongsTo.topic isEqualToString:[delegate theGeneralTopic]]) {
        self.UIremark.enabled = TRUE;
        self.UIradius.enabled = TRUE;
        self.UIshare.enabled = TRUE;
    } else {
        self.UIremark.enabled = FALSE;
        self.UIradius.enabled = FALSE;
        self.UIshare.enabled = FALSE;
    }
}

- (IBAction)sharechanged:(UISwitch *)sender {
    self.location.share = @(sender.on);
    self.needsUpdate = TRUE;
}

- (IBAction)remarkchanged:(UITextField *)sender {
    if (![sender.text isEqualToString:self.location.remark]) {
        self.location.remark = sender.text;
        self.needsUpdate = TRUE;
    }
}
- (IBAction)radiuschanged:(UITextField *)sender {
    if ([sender.text doubleValue] != [self.location.regionradius doubleValue]) {
        self.location.regionradius = @([sender.text doubleValue]);
        self.needsUpdate = TRUE;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.UIplace.text = self.location.placemark;
}

@end
