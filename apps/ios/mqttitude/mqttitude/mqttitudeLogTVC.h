//
//  mqttitudeLogTVC.h
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Logs.h"

@interface mqttitudeLogTVC : UITableViewController <LogsDelegate>
@property (strong, nonatomic) Logs *logs;
@end
