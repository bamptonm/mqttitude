//
//  mqttitudeQoSTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 19.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeQoSTVC.h"

@interface mqttitudeQoSTVC ()
@property (weak, nonatomic) IBOutlet UITableViewCell *UIqos0;
@property (weak, nonatomic) IBOutlet UITableViewCell *UIqos1;
@property (weak, nonatomic) IBOutlet UITableViewCell *UIqos2;

@end

@implementation mqttitudeQoSTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (void)setup
{
    [self.UIqos0 setAccessoryType:(self.qos == 0) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
    [self.UIqos1 setAccessoryType:(self.qos == 1) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
    [self.UIqos2 setAccessoryType:(self.qos == 2) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.qos = indexPath.row;
    [self setup];
}

+ (NSString *)qosString:(NSInteger)qos
{
    NSArray *qosStrings = @[
                            NSLocalizedString(@"At most once (0)", @"MQTT QoS 0"),
                            NSLocalizedString(@"At least once (1)", @"MQTT QoS 1"),
                            NSLocalizedString(@"Exactly once (2)", @"MQTT QoS 2")
                            ];
    
    if (qos < [qosStrings count]) {
        return qosStrings[qos];
    } else {
        return @"MQTTitude unknown QoS";
    }
}

@end


