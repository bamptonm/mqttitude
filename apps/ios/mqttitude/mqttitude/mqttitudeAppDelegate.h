//
//  mqttitudeAppDelegate.h
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Connection.h"
#import "Location+Create.h"
#import "mqttitudeSettings.h"

@interface mqttitudeAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, ConnectionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager *manager;
@property (nonatomic) NSInteger monitoring;
@property (strong, nonatomic) Connection *connection;
@property (strong, nonatomic) mqttitudeSettings *settings;

- (void)switchOff;
- (void)sendNow;
- (void)sendWayPoint:(Location *)location;
- (void)reconnect;
- (void)connectionOff;
- (void)saveContext;

@end
