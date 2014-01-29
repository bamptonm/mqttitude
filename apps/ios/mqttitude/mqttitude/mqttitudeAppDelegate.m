//
//  mqttitudeAppDelegate.m
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeAppDelegate.h"
#import "mqttitudeCoreData.h"
#import "Friend+Create.h"
#import "Location+Create.h"
#import "mqttitudeAlertView.h"

@interface mqttitudeAppDelegate()
@property (strong, nonatomic) NSTimer *disconnectTimer;
@property (strong, nonatomic) NSTimer *activityTimer;
@property (strong, nonatomic) UIAlertView *alertView;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (strong, nonatomic) mqttitudeCoreData *coreData;
@property (strong, nonatomic) NSDate *locationLastSent;
@property (strong, nonatomic) NSString *processingMessage;

@end

#define BACKGROUND_DISCONNECT_AFTER 8.0
#define REMINDER_AFTER 300.0

#define MAX_OWN_LOCATIONS 50
#define MAX_OTHER_LOCATIONS 1

#undef REMOTE_NOTIFICATIONS
#undef REMOTE_COMMANDS
#define BATTERY_MONITORING


@implementation mqttitudeAppDelegate

#pragma ApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    NSLog(@"App willFinishLaunchingWithOptions");
    NSEnumerator *enumerator = [launchOptions keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject])) {
        NSLog(@"App options %@:%@", key, [[launchOptions objectForKey:key] description]);
    }
#endif
    
    self.backgroundTask = UIBackgroundTaskInvalid;
    
    NSDictionary *appDefaults = @{
                                  @"mindist_preference" : @(200),
                                  @"mintime_preference" : @(180),
                                  @"deviceid_preference" : @"",
                                  @"clientid_preference" : @"",
                                  @"subscription_preference" : @"mqttitude/#",
                                  @"subscriptionqos_preference": @(1),
                                  @"topic_preference" : @"",
                                  @"retain_preference": @(TRUE),
                                  @"qos_preference": @(1),
                                  @"host_preference" : @"host",
                                  @"port_preference" : @(8883),
                                  @"tls_preference": @(YES),
                                  @"auth_preference": @(YES),
                                  @"user_preference": @"user",
                                  @"pass_preference": @"pass",
                                  @"keepalive_preference" : @(60),
                                  @"clean_preference" : @(NO),
                                  @"will_preference": @"lwt",
                                  @"willtopic_preference": @"",
                                  @"willretain_preference":@(NO),
                                  @"willqos_preference": @(1),
                                  @"monitoring_preference": @(1),
                                  @"ab_preference": @(YES)
                                  };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    NSLog(@"App didFinishLaunchingWithOptions");
    NSEnumerator *enumerator = [launchOptions keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject])) {
        NSLog(@"App options %@:%@", key, [[launchOptions objectForKey:key] description]);
    }
#endif
    
    /*
     * Core Data using UIManagedDocument
     */
    
    self.coreData = [[mqttitudeCoreData alloc] init];
    UIDocumentState state;
    
    do {
        state = self.coreData.documentState;
        if (state || ![mqttitudeCoreData theManagedObjectContext]) {
#ifdef DEBUG
            NSLog(@"APP Waiting for document to open documentState = 0x%02x theManagedObjectContext = %@",
                  self.coreData.documentState, [mqttitudeCoreData theManagedObjectContext]);
#endif
            if (state & UIDocumentStateInConflict || state & UIDocumentStateSavingError) {
                [mqttitudeAlertView alert:@"App Failure"
                                  message:[NSString stringWithFormat:@"Open document documentState = 0x%02x", state]];
                break;
            }
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    } while (state || ![mqttitudeCoreData theManagedObjectContext]);
    
    /*
     * CLLocationManager
     */
    
    if ([CLLocationManager locationServicesEnabled]) {
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            self.manager = [[CLLocationManager alloc] init];
            self.locationLastSent = [NSDate date]; // Do not sent old locations
            self.manager.delegate = self;
            
            self.monitoring = [[NSUserDefaults standardUserDefaults] integerForKey:@"monitoring_preference"];
            
            for (CLRegion *region in self.manager.monitoredRegions) {
                [self.manager stopMonitoringForRegion:region];
            }
        }
    }
    
    /*
     * MQTT connection
     */
        
    self.connection = [[Connection alloc] init];
    self.connection.delegate = self;
    
    [self connect];
  
#ifdef REMOTE_NOTIFICATIONS
    /*
     * Remote Notifications
     */
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
#endif
    
#ifdef BATTERY_MONITORING
    
    // Register for battery level and state change notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelChanged:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryStateChanged:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
#endif

    return YES;
}

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = [mqttitudeCoreData theManagedObjectContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges]) {
            NSError *error = nil;
#ifdef DEBUG
            NSLog(@"App save context");
#endif
            if (![managedObjectContext save:&error]) {
                NSString *message = [NSString stringWithFormat:@"CoreData unresolved error %@, %@", error, [error userInfo]];
#ifdef DEBUG
                NSLog(@"%@", message);
#endif
                [mqttitudeAlertView alert:@"App Failure" message:[message substringToIndex:128]];
            }
        }
    }
}

#ifdef BATTERY_MONITORING
- (void)batteryLevelChanged:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"App batteryLevelChanged %f", [UIDevice currentDevice].batteryLevel);
#endif

    // No, we do not want to switch off location monitoring when battery gets low
}

- (void)batteryStateChanged:(NSNotification *)notification
{
#ifdef DEBUG
    const NSDictionary *states = @{
                                   @(UIDeviceBatteryStateUnknown): @"unknown",
                                   @(UIDeviceBatteryStateUnplugged): @"unplugged",
                                   @(UIDeviceBatteryStateCharging): @"charging",
                                   @(UIDeviceBatteryStateFull): @"full"
                                   };
    
    NSLog(@"App batteryLevelChanged %@ (%d)", states[@([UIDevice currentDevice].batteryState)], [UIDevice currentDevice].batteryState);
#endif
}
#endif

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
#ifdef DEBUG
    NSLog(@"App openURL %@ from %@ annotation %@", url, sourceApplication, annotation);
#endif
    
    if (url) {
        NSError *error;
        NSInputStream *input = [NSInputStream inputStreamWithURL:url];
        if ([input streamError]) {
            self.processingMessage = [NSString stringWithFormat:@"Error nputStreamWithURL %@ %@", [input streamError], url];
            return FALSE;
        }
        [input open];
        if ([input streamError]) {
            self.processingMessage = [NSString stringWithFormat:@"Error open %@ %@", [input streamError], url];
            return FALSE;
        }
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithStream:input options:0 error:&error];
        if (dictionary) {
            for (NSString *key in [dictionary allKeys]) {
                NSLog(@"Configuration %@:%@", key, dictionary[key]);
            }
            
            if ([dictionary[@"_type"] isEqualToString:@"configuration"]) {
                NSString *string;
                
                string = dictionary[@"deviceid"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"deviceid_preference"];
                
                string = dictionary[@"clientid"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"clientid_preference"];
                
                string = dictionary[@"subscription"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"subscription_preference"];
                
                string = dictionary[@"topic"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"topic_preference"];
                
                string = dictionary[@"host"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"host_preference"];
                
                string = dictionary[@"user"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"user_preference"];
                
                string = dictionary[@"pass"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"pass_preference"];
                
                string = dictionary[@"will"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"will_preference"];
                
                string = dictionary[@"willtopic"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"willtopic_preference"];
                
                
                string = dictionary[@"subscriptionqos"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"subscriptionqos_preference"];
                
                string = dictionary[@"qos"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"qos_preference"];
                
                string = dictionary[@"port"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"port_preference"];
                
                string = dictionary[@"keepalive"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"keepalive_preference"];
                
                string = dictionary[@"willqos"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"willqos_preference"];
                
                string = dictionary[@"mindist"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"mindist_preference"];
                
                string = dictionary[@"mintime"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"mintime_preference"];
                
                string = dictionary[@"monitoring"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"monitoring_preference"];
                
                
                string = dictionary[@"retain"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"retain_preference"];
                
                string = dictionary[@"tls"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"tls_preference"];
                
                string = dictionary[@"auth"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"auth_preference"];
                
                string = dictionary[@"clean"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"clean_preference"];
                
                string = dictionary[@"willretain"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"willretain_preference"];

                string = dictionary[@"ab"];
                if (string) [[NSUserDefaults standardUserDefaults] setObject:@([string integerValue]) forKey:@"ab_preference"];
                
            } else {
                self.processingMessage = [NSString stringWithFormat:@"Error invalid configuration file %@)", dictionary[@"_type"]];
                return FALSE;
            }
        } else {
            self.processingMessage = [NSString stringWithFormat:@"Error illegal json in configuration file %@)", error];
            return FALSE;
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.processingMessage = [NSString stringWithFormat:@"Configuration file %@ successfully processed)", [url lastPathComponent]];
        
    }
    
    return TRUE;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
#ifdef DEBUG
    NSLog(@"App applicationWillResignActive");
#endif
    [self saveContext];
    [self.connection disconnect];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
#ifdef DEBUG
    NSLog(@"App applicationDidEnterBackground");
#endif
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                           {
#ifdef DEBUG
                               NSLog(@"BackgroundTaskExpirationHandler");
#endif

                               /*
                                * we might end up here if the connection could not be closed within the given
                                * background time
                                */ 
                               if (self.backgroundTask) {
                                   [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                                   self.backgroundTask = UIBackgroundTaskInvalid;
                               }
                           }];
    if ([UIApplication sharedApplication].applicationIconBadgeNumber) {
        [self notification:@"MQTTitude has undelivered messages. Tap to restart"
                     after:REMINDER_AFTER
                  userInfo:@{@"event": @"undelivered"}];
    }
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
#ifdef DEBUG
    NSLog(@"App applicationWillEnterForeground");
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
#ifdef DEBUG
    NSLog(@"App applicationDidBecomeActive");
#endif
    
    if (self.processingMessage) {
        [mqttitudeAlertView alert:@"App File Processing" message:self.processingMessage];
        self.processingMessage = nil;
        [self reconnect];
    }
    
    if (self.coreData.documentState) {
        NSString *message = [NSString stringWithFormat:@"Open CoreData %@ 0x%02x",
                             self.coreData.fileURL,
                             self.coreData.documentState];
        [mqttitudeAlertView alert:@"App Failure" message:message];
    }
    if (![CLLocationManager significantLocationChangeMonitoringAvailable]) {
        NSString *message = @"No significant location change monitoring available";
        [mqttitudeAlertView alert:@"App Failure" message:message];
    }
    if (![CLLocationManager locationServicesEnabled]) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        NSString *message = [NSString stringWithFormat:@"%@ %d",
                             @"ANot authorized for CoreLocation",
                             status];
        [mqttitudeAlertView alert:@"App Failure" message:message];
    }
    [self.connection connectToLast];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
#ifdef DEBUG
    NSLog(@"App applicationWillTerminate");
#endif
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self saveContext];
    [self notification:@"MQTTitude terminated. Tap to restart" userInfo:nil];
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notification
{
#ifdef DEBUG
    NSLog(@"App didReceiveLocalNotification %@", notification.alertBody);
#endif
}

#pragma CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
#ifdef DEBUG
    NSLog(@"App didUpdateLocations");
#endif

    for (CLLocation *location in locations) {
#ifdef DEBUG
        NSLog(@"App location %@", [location description]);
#endif
        if ([location.timestamp compare:self.locationLastSent] != NSOrderedAscending ) {
            [self publishLocation:location automatic:YES addon:nil];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"App locationManager:didFailWithError %@", error);
#endif
    NSString *message = [NSString stringWithFormat:@"didFailWithError %@", error];
    [mqttitudeAlertView alert:@"App locationManager" message:message];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
#ifdef DEBUG
    NSLog(@"App didEnterRegion %@", region);
#endif
    NSString *message = [NSString stringWithFormat:@"Entering %@", region.identifier];
    [self notification:message userInfo:nil];
    
    NSMutableDictionary *addon = [[NSMutableDictionary alloc] init];
    
    for (Location *location in [Location allRegionsOfTopic:[self theGeneralTopic]
                                    inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]]) {
        if ([location.remark isEqualToString:region.identifier]) {
            location.remark = region.identifier; // this touches the location and updates the overlay
            if ([location.share boolValue]) {
                [addon setObject:@"enter" forKey:@"event" ];
                if (location.remark) {
                    [addon setValue:location.remark forKey:@"desc"];
                }
                double rad = [location.regionradius doubleValue];
                if (rad > 0) {
                    [addon setValue:[NSString stringWithFormat:@"%.0f", rad] forKey:@"rad"];
                }
            }
        }
    }

    [self publishLocation:[manager location] automatic:TRUE addon:addon];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
#ifdef DEBUG
    NSLog(@"App didExitRegion %@", region);
#endif

    NSString *message = [NSString stringWithFormat:@"Leaving %@", region.identifier];
    [self notification:message userInfo:nil];
    
    NSMutableDictionary *addon = [[NSMutableDictionary alloc] init];
    
    for (Location *location in [Location allRegionsOfTopic:[self theGeneralTopic]
                                    inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]]) {
        if ([location.remark isEqualToString:region.identifier]) {
            location.remark = region.identifier; // this touches the location and updates the overlay
            if ([location.share boolValue]) {
                [addon setObject:@"leave" forKey:@"event" ];
                if (location.remark) {
                    [addon setValue:location.remark forKey:@"desc"];
                }
                double rad = [location.regionradius doubleValue];
                if (rad > 0) {
                    [addon setValue:[NSString stringWithFormat:@"%.0f", rad] forKey:@"rad"];
                }
            }
        }
    }

    [self publishLocation:[manager location] automatic:TRUE addon:addon];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
#ifdef DEBUG
    NSLog(@"App didStartMonitoringForRegion %@", region);
#endif
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"App monitoringDidFailForRegion %@ %@", region, error);
#endif
    NSString *message = [NSString stringWithFormat:@"monitoringDidFailForRegion %@ %@", region, error];
    [mqttitudeAlertView alert:@"App locationManager" message:message];
}

#pragma ConnectionDelegate

- (void)showState:(NSInteger)state
{
    id<ConnectionDelegate> cd;
    
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
        if ([nc.topViewController respondsToSelector:@selector(showState:)]) {
            cd = (id<ConnectionDelegate>)nc.topViewController;
        }
    } else if ([self.window.rootViewController respondsToSelector:@selector(showState:)]) {
        cd = (id<ConnectionDelegate>)self.window.rootViewController;
    }
    [cd showState:state];

    /**
     ** This is a hack to ensure the connection gets gracefully closed at the server
     **
     ** If the background task is ended, occasionally the disconnect message is not received well before the server senses the tcp disconnect
     **/
    
    if (state == state_closed) {
        if (self.backgroundTask) {
#ifdef DEBUG
            NSLog(@"App endBackGroundTask");
#endif
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }
    }
}

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic
{
    if ([topic isEqualToString:[self theGeneralTopic]]) {
        // received own data
        
#ifdef REMOTE_COMMANDS
    } else if ([topic isEqualToString:[NSString stringWithFormat:@"%@/%@", [self theGeneralTopic], @"msg"]]) {
#ifdef DEBUG
        NSLog(@"App received msg %@", data);
#endif
        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (dictionary) {
            if ([dictionary[@"_type"] isEqualToString:@"msg"]) {
                NSLog(@"App msg received text:%@ from:%@",
                      dictionary[@"text"],
                      dictionary[@"from"]
                      );
                [self notification:[NSString stringWithFormat:@"%@ from %@",
                                    dictionary[@"text"],
                                    dictionary[@"from"]]];
            } else {
#ifdef DEBUG
                NSLog(@"App received unknown record type %@)", dictionary[@"_type"]);
#endif
                // data other than json _type msg is silently ignored
            }
        } else {
#ifdef DEBUG
            NSLog(@"App received illegal json %@)", error);
#endif
            // data other than json is silently ignored
        }
#endif
        
    } else if ([topic isEqualToString:[NSString stringWithFormat:@"%@/%@", [self theGeneralTopic], @"waypoints"]]) {
        // received own waypoint
    } else {
        // received other data
        NSString *deviceName = topic;
        if ([[deviceName lastPathComponent] isEqualToString:@"deviceToken"]) {
            deviceName = [deviceName stringByDeletingLastPathComponent];
        }
        if ([[deviceName lastPathComponent] isEqualToString:@"waypoints"]) {
            deviceName = [deviceName stringByDeletingLastPathComponent];
        }
        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (dictionary) {
            if ([dictionary[@"_type"] isEqualToString:@"location"] ||
                [dictionary[@"_type"] isEqualToString:@"waypoint"]) {
#ifdef DEBUG
                NSLog(@"App json received lat:%f lon:%f acc:%f tst:%f rad:%f event:%@ desc:%@",
                      [dictionary[@"lat"] doubleValue],
                      [dictionary[@"lon"] doubleValue],
                      [dictionary[@"acc"] doubleValue],
                      [dictionary[@"tst"] doubleValue],
                      [dictionary[@"rad"] doubleValue],
                      dictionary[@"event"],
                      dictionary[@"desc"]
                      );
#endif
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
                                                                               [dictionary[@"lat"] doubleValue],
                                                                               [dictionary[@"lon"] doubleValue]
                                                                               );
                
                CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                                     altitude:0
                                                           horizontalAccuracy:[dictionary[@"acc"] doubleValue]
                                                             verticalAccuracy:-1
                                                                    timestamp:[NSDate dateWithTimeIntervalSince1970:[dictionary[@"tst"] doubleValue]]];

                Location *newLocation = [Location locationWithTopic:deviceName
                                                          timestamp:location.timestamp
                                                         coordinate:location.coordinate
                                                           accuracy:location.horizontalAccuracy
                                                          automatic:[dictionary[@"_type"] isEqualToString:@"location"] ? TRUE : FALSE
                                                             remark:dictionary[@"desc"]
                                                             radius:[dictionary[@"rad"] doubleValue]
                                                              share:NO
                                             inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
                [self limitLocationsWith:newLocation.belongsTo toMaximum:MAX_OTHER_LOCATIONS];
                
                if (dictionary[@"event"]) {
                    NSString * name = [newLocation.belongsTo name];
                    [self notification:[NSString stringWithFormat:@"%@ %@s %@",
                                        name ? name : newLocation.belongsTo.topic,
                                        dictionary[@"event"],
                                        newLocation.remark]
                              userInfo:nil];
                }
                
            } else if ([dictionary[@"_type"] isEqualToString:@"deviceToken"]) {
                Friend *friend = [Friend friendWithTopic:deviceName inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
                friend.device = dictionary[@"deviceToken"];
                
            } else {
#ifdef DEBUG
                NSLog(@"App received unknown record type %@)", dictionary[@"_type"]);
#endif
                // data other than json _type location/waypoint is silently ignored
            }
        } else {
#ifdef DEBUG
            NSLog(@"App received illegal json %@)", error);
#endif
            // data other than json is silently ignored
        }
    }
    [self saveContext];
}

- (void)messageDelivered:(UInt16)msgID
{
    NSString *message = [NSString stringWithFormat:@"Message delivered id=%u", msgID];
    [self notification:message userInfo:nil];
}

- (void)totalBuffered:(NSUInteger)count
{
    id<ConnectionDelegate> cd;
    
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
        if ([nc.topViewController respondsToSelector:@selector(totalBuffered:)]) {
            cd = (id<ConnectionDelegate>)nc.topViewController;
        }
    } else if ([self.window.rootViewController respondsToSelector:@selector(totalBuffered:)]) {
        cd = (id<ConnectionDelegate>)self.window.rootViewController;
    }
    [cd totalBuffered:count];
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
    if (!count) {
        NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification *notification in notifications) {
            if (notification.userInfo) {
                [[UIApplication sharedApplication] cancelLocalNotification:notification];
            }
        }
    }
}

#pragma actions

- (void)switchOff
{
#ifdef DEBUG
    NSLog(@"App switchOff");
#endif

    [self saveContext];
    [self connectionOff];
    self.monitoring = 0;
    [[NSUserDefaults standardUserDefaults] synchronize];
    exit(0);
}
- (void)sendNow
{
#ifdef DEBUG
    NSLog(@"App sendNow");
#endif

    [self publishLocation:[self.manager location] automatic:FALSE addon:nil];
}
- (void)connectionOff
{
#ifdef DEBUG
    NSLog(@"App connectionOff");
#endif
    
    [self.connection disconnect];
}

- (void)setMonitoring:(NSInteger)monitoring
{
#ifdef DEBUG
    NSLog(@"App monitoring=%ld", (long)monitoring);
#endif

    _monitoring = monitoring;
    [[NSUserDefaults standardUserDefaults] setObject:@(monitoring) forKey:@"monitoring_preference"];

    switch (monitoring) {
        case 2:
            self.manager.distanceFilter = [[NSUserDefaults standardUserDefaults] doubleForKey:@"mindist_preference"];
            self.manager.desiredAccuracy = kCLLocationAccuracyBest;
            self.manager.pausesLocationUpdatesAutomatically = YES;
            [self.manager stopMonitoringSignificantLocationChanges];
            
            [self.manager startUpdatingLocation];
            self.activityTimer = [NSTimer timerWithTimeInterval:[[NSUserDefaults standardUserDefaults] doubleForKey:@"mintime_preference"] target:self selector:@selector(activityTimer:) userInfo:Nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.activityTimer forMode:NSRunLoopCommonModes];
            break;
        case 1:
            [self.activityTimer invalidate];
            [self.manager stopUpdatingLocation];
            [self.manager startMonitoringSignificantLocationChanges];
            break;
        case 0:
        default:
            [self.activityTimer invalidate];
            [self.manager stopUpdatingLocation];
            [self.manager stopMonitoringSignificantLocationChanges];
            break;
    }
}

- (void)activityTimer:(NSTimer *)timer
{
#ifdef DEBUG
    NSLog(@"App activityTimer");
#endif
    [self publishLocation:[self.manager location] automatic:TRUE addon:nil];
}

- (void)reconnect
{
#ifdef DEBUG
    NSLog(@"App reconnect");
#endif

    [self.connection disconnect];
    [self connect];
}

- (void)publishLocation:(CLLocation *)location automatic:(BOOL)automatic addon:(NSDictionary *)addon
{
    self.locationLastSent = location.timestamp;
    
    Location *newLocation = [Location locationWithTopic:[self theGeneralTopic]
                                              timestamp:location.timestamp
                                             coordinate:location.coordinate
                                               accuracy:location.horizontalAccuracy
                                              automatic:automatic
                                                 remark:nil
                                                 radius:0
                                                  share:NO
                                 inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
    
    NSData *data = [self encodeLocationData:newLocation type:@"location" addon:addon];
    
    long msgID = [self.connection sendData:data
                                       topic:[self theGeneralTopic]
                                         qos:[[NSUserDefaults standardUserDefaults] integerForKey:@"qos_preference"]
                                      retain:[[NSUserDefaults standardUserDefaults] boolForKey:@"retain_preference"]];
    
    if (msgID <= 0) {
        NSString *message = [NSString stringWithFormat:@"Location %@",
                             (msgID == -1) ? @"queued" : @"sent"];
        [self notification:message userInfo:nil];
        
    }
    
    [self limitLocationsWith:newLocation.belongsTo toMaximum:MAX_OWN_LOCATIONS];
    
    /**
     *   In background, set timer to disconnect after BACKGROUND_DISCONNECT_AFTER sec. IOS will suspend app after 10 sec.
     **/
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if (self.disconnectTimer) {
            [self.disconnectTimer invalidate];
        }
        self.disconnectTimer = [NSTimer timerWithTimeInterval:BACKGROUND_DISCONNECT_AFTER
                                                       target:self
                                                     selector:@selector(disconnectInBackground)
                                                     userInfo:Nil repeats:FALSE];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self.disconnectTimer
                  forMode:NSDefaultRunLoopMode];
    }
    [self saveContext];
}

- (void)sendWayPoint:(Location *)location
{
    NSMutableDictionary *addon = [[NSMutableDictionary alloc]init];
    
    if (location.remark) {
        [addon setValue:location.remark forKey:@"desc"];
    }
    double rad = [location.regionradius doubleValue];
    if (rad > 0) {
        [addon setValue:[NSString stringWithFormat:@"%.0f", rad] forKey:@"rad"];
    }

    NSData *data = [self encodeLocationData:location
                                       type:@"waypoint" addon:addon];
    
    long msgID = [self.connection sendData:data
                                          topic:[[self theGeneralTopic] stringByAppendingString:@"/waypoints"]
                                            qos:[[NSUserDefaults standardUserDefaults] integerForKey:@"qos_preference"]
                                         retain:NO];
    
    if (msgID <= 0) {
        NSString *message = [NSString stringWithFormat:@"Waypoint %@",
                             (msgID == -1) ? @"queued" : @"sent"];
        [self notification:message userInfo:nil];
        
    }
    [self saveContext];
}

- (void)limitLocationsWith:(Friend *)friend toMaximum:(NSInteger)max
{
    NSArray *allLocations = [Location allAutomaticLocationsWithFriend:friend inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
    
    for (NSInteger i = [allLocations count]; i > max; i--) {
            Location *location = allLocations[i - 1];
        [[mqttitudeCoreData theManagedObjectContext] deleteObject:location];
    }
}

#pragma internal helpers

- (void)notification:(NSString *)message userInfo:(NSDictionary *)userInfo
{
    [self notification:message after:0 userInfo:nil];
}

- (void)notification:(NSString *)message after:(NSTimeInterval)after userInfo:(NSDictionary *)userInfo
{
#ifdef DEBUG
    NSLog(@"App notification %@", message);
#endif
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.alertLaunchImage = @"itunesArtwork.png";
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:after];
    notification.userInfo = userInfo;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)connect
{
    [self.connection connectTo:[[NSUserDefaults standardUserDefaults] stringForKey:@"host_preference"]
                          port:[[NSUserDefaults standardUserDefaults] integerForKey:@"port_preference"]
                           tls:[[NSUserDefaults standardUserDefaults] boolForKey:@"tls_preference"]
                     keepalive:[[NSUserDefaults standardUserDefaults] integerForKey:@"keepalive_preference"]
                         clean:[[NSUserDefaults standardUserDefaults] integerForKey:@"clean_preference"]
                          auth:[[NSUserDefaults standardUserDefaults] boolForKey:@"auth_preference"]
                          user:[[NSUserDefaults standardUserDefaults] stringForKey:@"user_preference"]
                          pass:[[NSUserDefaults standardUserDefaults] stringForKey:@"pass_preference"]
                     willTopic:[self theWillTopic]
                          will:[self jsonToData:@{
                                                  @"tst": [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]],
                                                  @"_type": @"lwt"}]
                       willQos:[[NSUserDefaults standardUserDefaults] integerForKey:@"willqos_preference"]
                willRetainFlag:[[NSUserDefaults standardUserDefaults] boolForKey:@"willretain_preference"]
                  withClientId:[self theClientId]];
}

- (void)disconnectInBackground
{
#ifdef DEBUG
    NSLog(@"App disconnectInBackground");
#endif
    
    self.disconnectTimer = nil;
    [self.connection disconnect];
    
    if ([UIApplication sharedApplication].applicationIconBadgeNumber) {
        [self notification:@"MQTTitude has still undelivered messages. Tap to restart" after:0];
    }
}

- (NSData *)jsonToData:(NSDictionary *)jsonObject
{
    NSData *data;
    
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        NSError *error;
        data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 /* not pretty printed */ error:&error];
        if (!data) {
            NSString *message = [NSString stringWithFormat:@"Error %@ serializing JSON Object: %@", [error description], [jsonObject description]];
            [mqttitudeAlertView alert:@"App Failure" message:message];
        }
    } else {
        NSString *message = [NSString stringWithFormat:@"No valid JSON Object: %@", [jsonObject description]];
        [mqttitudeAlertView alert:@"App Failure" message:message];
    }
    return data;
}


- (NSData *)encodeLocationData:(Location *)location type:(NSString *)type addon:(NSDictionary *)addon
{
    NSMutableDictionary *jsonObject = [@{
                                 @"lat": [NSString stringWithFormat:@"%f", location.coordinate.latitude],
                                 @"lon": [NSString stringWithFormat:@"%f", location.coordinate.longitude],
                                 @"tst": [NSString stringWithFormat:@"%.0f", [location.timestamp timeIntervalSince1970]],
                                 @"acc": [NSString stringWithFormat:@"%.0f", [location.accuracy doubleValue]],
                                 @"_type": [NSString stringWithFormat:@"%@", type]
                                 } mutableCopy];
    if (addon) {
        [jsonObject addEntriesFromDictionary:addon];
    }
    
#ifdef BATTERY_MONITORING
    [jsonObject setValue:[NSString stringWithFormat:@"%.0f", [UIDevice currentDevice].batteryLevel != -1.0 ?
                          [UIDevice currentDevice].batteryLevel * 100.0 : -1.0] forKey:@"batt"];
#endif

    return [self jsonToData:jsonObject];
}

#ifdef REMOTE_NOTIFICATIONS

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"App didFailToRegisterForRemoteNotificationsWithError %@", error);
#endif
        NSString *message = [NSString stringWithFormat:@"App didFailToRegisterForRemoteNotificationsWithError %@", error];
        [mqttitudeAlertView alert:@"App Failure" message:message];

}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
#ifdef DEBUG
    NSLog(@"App didReceiveRemoteNotification %@", userInfo);
#endif
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
#ifdef DEBUG
    NSLog(@"App didReceiveRemoteNotification fetchCompletionHandler %@", userInfo);
#endif
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
#ifdef DEBUG
    NSLog(@"App didRegisterForRemoteNotificationsWithDeviceToken %@", deviceToken);
#endif
    
    NSDictionary *jsonObject = @{
                                 @"tst": [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]],
                                 @"dev": [NSString stringWithFormat:@"%@", [deviceToken description]],
                                 @"_type": [NSString stringWithFormat:@"%@", @"deviceToken"]
                                 };

    [self.connection sendData:[self jsonToData:jsonObject]
                        topic:[NSString stringWithFormat:@"%@/deviceToken", self.theGeneralTopic]
                          qos:1
                       retain:YES];
}
#endif // REMOTE_NOTIFICATIONS

#pragma construct topic names

- (NSString *)theGeneralTopic
{
    NSString *topic;
    topic = [[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"];
    
    if (!topic || [topic isEqualToString:@""]) {
        topic = [NSString stringWithFormat:@"mqttitude/%@", [self theId]];
    }
    return topic;
}

- (NSString *)theWillTopic
{
    NSString *topic;
    topic = [[NSUserDefaults standardUserDefaults] stringForKey:@"willtopic_preference"];
    
    if (!topic || [topic isEqualToString:@""]) {
        topic = [self theGeneralTopic];
    }
    
    return topic;
}

- (NSString *)theClientId
{
    NSString *clientId;
    clientId = [[NSUserDefaults standardUserDefaults] stringForKey:@"clientid_preference"];
    
    if (!clientId || [clientId isEqualToString:@""]) {
        clientId = [self theId];
    }
    return clientId;
}

- (NSString *)theId
{
    NSString *theId;
    NSString *user;
    user = [[NSUserDefaults standardUserDefaults] stringForKey:@"user_preference"];
    NSString *deviceId;
    deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceid_preference"];
    
        if (!user || [user isEqualToString:@""]) {
            if (!deviceId || [deviceId isEqualToString:@""]) {
                theId = [[UIDevice currentDevice] name];
            } else {
                theId = deviceId;
            }
        } else {
            if (!deviceId || [deviceId isEqualToString:@""]) {
                theId = user;
            } else {
                theId = [NSString stringWithFormat:@"%@/%@", user, deviceId];
            }
        }
    
    return theId;
}

- (NSString *)theDeviceId
{
    NSString *deviceId;
    deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceid_preference"];
    return deviceId;
}

@end
