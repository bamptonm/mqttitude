//
//  mqttitudePublishTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudePublishTVC.h"
#import "mqttitudeQoSTVC.h"
#import "Connection.h"

@interface mqttitudePublishTVC ()
@property (weak, nonatomic) IBOutlet UITextField *UItopic;
@property (weak, nonatomic) IBOutlet UITextView *UIdata;
@property (weak, nonatomic) IBOutlet UITextField *UIqos;
@property (weak, nonatomic) IBOutlet UISwitch *UIretainFlag;

@end

@implementation mqttitudePublishTVC 

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.UItopic.text = self.topic;
    self.UIdata.text = [Connection dataToString:self.data];
    self.UIdata.delegate = self;
    self.UIqos.text = [mqttitudeQoSTVC qosString:self.qos];
    self.UIretainFlag.on = self.retainFlag;
}
- (IBAction)topicChange:(UITextField *)sender {
    self.topic = sender.text;
}
- (IBAction)retainChange:(UISwitch *)sender {
    self.retainFlag = sender.on;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[mqttitudeQoSTVC class]]) {
        mqttitudeQoSTVC *qos = (mqttitudeQoSTVC *)segue.destinationViewController;
        qos.qos = self.qos;
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.data = [textView .text dataUsingEncoding:NSUTF8StringEncoding];
}

- (IBAction)settingsSaved:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[mqttitudeQoSTVC class]]) {
        mqttitudeQoSTVC *qos = (mqttitudeQoSTVC *)segue.sourceViewController;
        self.qos = qos.qos;
        self.UIqos.text = [mqttitudeQoSTVC qosString:qos.qos];
    }
}



@end
