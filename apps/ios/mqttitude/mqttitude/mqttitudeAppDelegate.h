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

@interface mqttitudeAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, ConnectionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager *manager;
@property (nonatomic) NSInteger monitoring;
@property (strong, nonatomic) Connection *connection;

- (void)switchOff;
- (void)sendNow;
- (void)reconnect;
- (void)connectionOff;

- (NSString *)theGeneralTopic;
- (NSString *)theWillTopic;
- (NSString *)theClientId;
- (NSString *)theDeviceId;

@end
