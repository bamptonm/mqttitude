//
//  mqttitudePublicationTVC.h
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mqttitudePublicationTVC : UITableViewController <UITextViewDelegate>
@property (strong, nonatomic) NSString *topic;
@property (strong, nonatomic) NSString *oldTopic;
@property (strong, nonatomic) NSData *data;
@property (nonatomic) NSInteger qos;
@property (nonatomic) BOOL retainFlag;

@end
