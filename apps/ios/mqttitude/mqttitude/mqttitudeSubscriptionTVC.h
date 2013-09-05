//
//  mqttitudeSubscriptionTVC.h
//  mqttitude
//
//  Created by Christoph Krey on 31.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mqttitudeSubscriptionTVC : UITableViewController
@property (strong, nonatomic) NSString *topic;
@property (strong, nonatomic) NSString *oldTopic;

@property (nonatomic) NSInteger qos;
@end
