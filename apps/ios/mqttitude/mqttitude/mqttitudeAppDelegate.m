//
//  mqttitudeAppDelegate.m
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeAppDelegate.h"


@interface mqttitudeAppDelegate()
@property (strong, nonatomic) Annotations *annotations;
@property (strong, nonatomic) NSTimer *disconnectTimer;

@end

@implementation mqttitudeAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
#ifdef DEBUG
    NSLog(@"application didFinishLaunchingWithOptions");
    NSEnumerator *enumerator = [launchOptions keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject])) {
        NSLog(@"%@:%@", key, [[launchOptions objectForKey:key] description]);
    }
#endif
    NSDictionary *appDefaults = @{
                                  @"subscription_preference" : @"#",
                                  @"subscriptionqos_preference": @(1),
                                  @"topic_preference" : @"loc",
                                 @"retain_preference": @(TRUE),
                                 @"qos_preference": @(1),
                                 @"host_preference" : @"host",
                                 @"port_preference" : @(1883),
                                 @"tls_preference": @(NO),
                                 @"auth_preference": @(NO),
                                 @"user_preference": @"user",
                                 @"auth_preference": @"pass",
                                 @"keepalive_preference" : @(60),
                                 @"clean_preference" : @(YES),
                                 @"will_preference": @"lwt",
                                 @"willtopic_preference": @"loc",
                                 @"willretain_preference":@(NO),
                                 @"willqos_preference": @(1),
                                };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.annotations = [[Annotations alloc] init];
    self.annotations.myTopic = [[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"];

    if ([self.window.rootViewController respondsToSelector:@selector(setAnnotations:)]) {
        [self.window.rootViewController performSelector:@selector(setAnnotations:) withObject:self.annotations];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            self.manager = [[CLLocationManager alloc] init];
            self.manager.delegate = self;
            [self.manager startMonitoringSignificantLocationChanges];
        } else {
            NSString *message = NSLocalizedString(@"No significant location change monitoring available", @"No significant location change monitoring available");
            [self alert:message];
        }
    } else {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        NSString *message = [NSString stringWithFormat:@"%@ %d",
                     NSLocalizedString(@"Application not authorized for CoreLocation", @"Application not authorized for CoreLocation"),
                     status];
        [self alert:message];
    }
        
    self.connection = [[Connection alloc] init];
    self.connection.delegate = self;
    
    [self.connection connectTo:[[NSUserDefaults standardUserDefaults] stringForKey:@"host_preference"]
                          port:[[NSUserDefaults standardUserDefaults] integerForKey:@"port_preference"]
                           tls:[[NSUserDefaults standardUserDefaults] boolForKey:@"tls_preference"]
                     keepalive:[[NSUserDefaults standardUserDefaults] integerForKey:@"keepalive_preference"]
                          auth:[[NSUserDefaults standardUserDefaults] boolForKey:@"auth_preference"]
                          user:[[NSUserDefaults standardUserDefaults] stringForKey:@"user_preference"]
                          pass:[[NSUserDefaults standardUserDefaults] stringForKey:@"pass_preference"]
                     willTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"willtopic_preference"]
                          will:[self jsonToData:@{
                                @"tst": [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]],
                                @"_type": @"lwt"}]
                       willQos:[[NSUserDefaults standardUserDefaults] integerForKey:@"willqos_preference"]
                willRetainFlag:[[NSUserDefaults standardUserDefaults] boolForKey:@"willretain_preference"]];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
#ifdef DEBUG
    NSLog(@"applicationWillResignActive");
    [self.connection disconnect];
#endif
}

- (void)expirationHandler
{
#ifdef DEBUG
    NSLog(@"ExpirationHandler remaining: %10.3f", [UIApplication sharedApplication].backgroundTimeRemaining);
#endif
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
#ifdef DEBUG
    NSLog(@"applicationDidEnterBackground");
#endif    
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
#ifdef DEBUG
    NSLog(@"applicationWillEnterForeground");
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
#ifdef DEBUG
    NSLog(@"applicationDidBecomeActive");
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
#ifdef DEBUG
    NSLog(@"applicationWillTerminate");
#endif
}

#pragma CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        [self publishLocation:location];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"locationMangager failed with Error %@", [error description]];
    [self alert:message];
}


#pragma ConnectionDelegate

- (void)showState:(NSInteger)state
{
    if ([self.window.rootViewController respondsToSelector:@selector(showState:)]) {
        id<ConnectionDelegate> cd = (id<ConnectionDelegate>)self.window.rootViewController;
        [cd showState:state];
    }
}

- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic
{
    NSString *message = [NSString stringWithFormat:@"%@: %@", topic, [Connection dataToString:data]];
    if ([topic isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"]]) {
        // received own data
    } else if ([topic isEqualToString:[NSString stringWithFormat:@"%@/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"], @"listento"]]) {
        // received command
        NSString *message = [Connection dataToString:data];
        if ([message isEqualToString:@"publish"]) {
            [self publishLocation:self.manager.location];
        } else {
            NSString *message = NSLocalizedString(@"MQTTitude received an unknown command", @"MQTTitude received an unknown command");
            [self alert:message];
        }
    } else if ([topic isEqualToString:[NSString stringWithFormat:@"%@/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"], @"message"]]) {
        [self notification:message];
        [self alert:message];
    } else {
        // received other data
        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (dictionary) {
            if ([dictionary[@"_type"] isEqualToString:@"location"]) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([dictionary[@"lat"] floatValue], [dictionary[@"lon"] floatValue]);
                CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                                     altitude:[dictionary[@"alt"] floatValue]
                                                           horizontalAccuracy:[dictionary[@"acc"] floatValue]
                                                             verticalAccuracy:[dictionary[@"vac"] floatValue]
                                                                    timestamp:[NSDate dateWithTimeIntervalSince1970:[dictionary[@"tst"] floatValue]]];
                [self.annotations addLocation:location topic:topic];
            }
        }
    }
}


- (void)alert:(NSString *)message
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSBundle mainBundle].infoDictionary[@"CFBundleName"]
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)notification:(NSString *)message
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.alertLaunchImage = @"itunesArtwork.png";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)switchOff
{
    [self.connection disconnect];
    [self.manager stopMonitoringSignificantLocationChanges];
    [[NSUserDefaults standardUserDefaults] synchronize];
    exit(0);
}
- (void)sendNow
{
    [self publishLocation:[self.manager location]];
}
- (void)reconnect
{
    [self.connection disconnect];
    
    self.annotations.myTopic = [[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"];

    [self.connection connectTo:[[NSUserDefaults standardUserDefaults] stringForKey:@"host_preference"]
                          port:[[NSUserDefaults standardUserDefaults] integerForKey:@"port_preference"]
                           tls:[[NSUserDefaults standardUserDefaults] boolForKey:@"tls_preference"]
                     keepalive:[[NSUserDefaults standardUserDefaults] integerForKey:@"keepalive_preference"]
                          auth:[[NSUserDefaults standardUserDefaults] boolForKey:@"auth_preference"]
                          user:[[NSUserDefaults standardUserDefaults] stringForKey:@"user_preference"]
                          pass:[[NSUserDefaults standardUserDefaults] stringForKey:@"pass_preference"]
                     willTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"willtopic_preference"]
                          will:[self jsonToData:@{
                                @"tst": [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]],
                                @"_type": @"lwt"}]
                       willQos:[[NSUserDefaults standardUserDefaults] integerForKey:@"willqos_preference"]
                willRetainFlag:[[NSUserDefaults standardUserDefaults] boolForKey:@"willretain_preference"]];
}

- (NSData *)jsonToData:(NSDictionary *)jsonObject
{
    NSData *data;
    
    
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        NSError *error;
        data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 /* not pretty printed */ error:&error];
        if (!data) {
            NSString *message = [NSString stringWithFormat:@"Error %@ serializing JSON Object: %@", [error description], [jsonObject description]];
            [self alert:message];
        }
    } else {
        NSString *message = [NSString stringWithFormat:@"No valid JSON Object: %@", [jsonObject description]];
        [self alert:message];
    }
    return data;
}

- (void)publishLocation:(CLLocation *)location
{
    [self.annotations addLocation:location topic:[[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"]];
    Annotation *annotation = [self.annotations myLastAnnotation];
    NSString *message = [NSString stringWithFormat:@"Published %@ %@", annotation.title, annotation.subtitle];
    [self notification:message];
    
    NSData *data = [self formatLocationData:location];
    [self.connection sendData:data
                        topic:[[NSUserDefaults standardUserDefaults]
                               stringForKey:@"topic_preference"]
                          qos:[[NSUserDefaults standardUserDefaults] integerForKey:@"qos_preference"]
                       retain:[[NSUserDefaults standardUserDefaults] boolForKey:@"retain_preference"]];
    
    /**
     *   In background, set timer to disconnect after 5 sec. IOS will suspend app after 10 sec.
     **/
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        self.disconnectTimer = [NSTimer timerWithTimeInterval:5.0
                                                       target:self
                                                     selector:@selector(disconnectInBackground)
                                                     userInfo:Nil repeats:FALSE];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self.disconnectTimer
                  forMode:NSDefaultRunLoopMode];
    }
}

- (void)disconnectInBackground
{
    self.disconnectTimer = nil;
    [self.connection disconnect];
}


- (NSData *)formatLocationData:(CLLocation *)location
{
    NSDictionary *jsonObject = @{
                                 @"lat": [NSString stringWithFormat:@"%f", location.coordinate.latitude],
                                 @"lon": [NSString stringWithFormat:@"%f", location.coordinate.longitude],
                                 @"tst": [NSString stringWithFormat:@"%.0f", [location.timestamp timeIntervalSince1970]],
                                 @"acc": [NSString stringWithFormat:@"%.0fm", location.horizontalAccuracy],
                                 @"alt": [NSString stringWithFormat:@"%f", location.altitude],
                                 @"vac": [NSString stringWithFormat:@"%.0fm", location.verticalAccuracy],
                                 @"vel": [NSString stringWithFormat:@"%f", location.speed],
                                 @"dir": [NSString stringWithFormat:@"%f", location.course],
                                 @"_type": [NSString stringWithFormat:@"%@", @"location"]
                                 };
    return [self jsonToData:jsonObject];
}

- (void)lowlevellog:(MQTTSession *)session component:(NSString *)component message:(NSString *)message mqttmsg:(MQTTMessage *)mqttmsg
{
    // Nothing to do here
}

@end
