//
//  mqttitudeAppDelegate.h
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Connection.h"
#import "Annotations.h"

@interface mqttitudeAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, ConnectionDelegate, AnnotationsDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager *manager;
@property (strong, nonatomic) Connection *connection;

- (void)switchOff;
- (void)sendNow;
- (void)reconnect;
- (void)connectionOff;
- (void)locationOn;
- (void)locationOff;

@end
