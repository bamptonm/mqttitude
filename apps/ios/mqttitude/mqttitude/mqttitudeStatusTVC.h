//
//  mqttitudeStatusTVC.h
//  mqttitude
//
//  Created by Christoph Krey on 11.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connection.h"

@interface mqttitudeStatusTVC : UITableViewController
@property (weak, nonatomic) Connection *connection;

@end
