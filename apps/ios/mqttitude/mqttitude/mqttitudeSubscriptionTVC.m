//
//  mqttitudeSubscriptionTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 31.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeSubscriptionTVC.h"
#import "mqttitudeQoSTVC.h"

@interface mqttitudeSubscriptionTVC ()
@property (weak, nonatomic) IBOutlet UITextField *UItopic;
@property (weak, nonatomic) IBOutlet UITextField *UIqos;

@end

@implementation mqttitudeSubscriptionTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.UItopic.text = self.topic;
    self.UIqos.text = [mqttitudeQoSTVC qosString:self.qos];
}
- (IBAction)topicChange:(UITextField *)sender {
    self.topic = sender.text;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[mqttitudeQoSTVC class]]) {
        mqttitudeQoSTVC *qos = (mqttitudeQoSTVC *)segue.destinationViewController;
            qos.qos = self.qos;
    } 
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
