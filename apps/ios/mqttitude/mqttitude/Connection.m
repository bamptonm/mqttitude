//
//  Connection.m
//  mqttitude
//
//  Created by Christoph Krey on 25.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Connection.h"

@interface Connection()

@property (nonatomic) NSInteger state;

@property (strong, nonatomic) NSTimer *reconnectTimer;
@property (nonatomic) float reconnectTime;

@property (strong, nonatomic) MQTTSession *session;
@property (strong, nonatomic) NSMutableArray *fifo;

@property (strong, nonatomic) NSData *lastData;
@property (strong, nonatomic) NSString *lastTopic;
@property (nonatomic) NSInteger lastQos;
@property (nonatomic) BOOL lastRetainFlag;

@property (strong, nonatomic) NSString *lastHost;
@property (nonatomic) NSInteger lastPort;
@property (nonatomic) BOOL lastTls;
@property (nonatomic) BOOL lastAuth;
@property (strong, nonatomic) NSString *lastUser;
@property (strong, nonatomic) NSString *lastPass;

@property (strong, nonatomic) NSData *lastWill;
@property (strong, nonatomic) NSString *lastWillTopic;
@property (nonatomic) BOOL lastClean;
@property (nonatomic) BOOL lastWillRetainFlag;
@property (nonatomic) NSInteger lastKeepalive;
@property (nonatomic) NSInteger lastWillQos;



@end

#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX 300.0

@implementation Connection

- (id)init
{
    self = [super init];
    self.state = state_starting;
    return self;
}

- (void)setState:(NSInteger)state
{
    _state = state;
#ifdef DEBUG
    NSLog(@"Connection state:%d", self.state);
#endif
    [self.delegate showState:self.state];
}

- (NSArray *)fifo
{
    if (!_fifo)
        _fifo = [[NSMutableArray alloc] init];
    return _fifo;
}


- (void)reconnect
{
#ifdef DEBUG
    NSLog(@"reconnect");
#endif
    self.reconnectTimer = nil;
    if (self.reconnectTime < RECONNECT_TIMER_MAX) {
        self.reconnectTime *= 2;
    }
    self.state = state_starting;
    
    [self connectToInternal];
}

/*
 * externally visible methods
 */

#define OTHERS @"#"
#define MQTT_KEEPALIVE 60

- (void)connectTo:(NSString *)host port:(NSInteger)port tls:(BOOL)tls keepalive:(NSInteger)keepalive auth:(BOOL)auth user:(NSString *)user pass:(NSString *)pass willTopic:(NSString *)willTopic will:(NSData *)will willQos:(NSInteger)willQos willRetainFlag:(BOOL)willRetainFlag
{
    self.lastHost = host;
    self.lastPort = port;
    self.lastTls = tls;
    self.lastKeepalive = keepalive;
    self.lastAuth = auth;
    self.lastUser = user;
    self.lastPass = pass;
    self.lastWillTopic = willTopic;
    self.lastWill = will;
    self.lastWillQos = willQos;
    self.lastWillRetainFlag = willRetainFlag;
    
    self.reconnectTime = RECONNECT_TIMER;
    
    [self connectToInternal];
}

- (void)connectToLast
{
    self.reconnectTime = RECONNECT_TIMER;
    
    [self connectToInternal];
}

- (void)sendData:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos retain:(BOOL)retainFlag
{
    self.lastData = data;
    self.lastTopic = topic;
    self.lastQos = qos;
    self.lastRetainFlag = retainFlag;
    
    [self sendInternal];
}

- (void)sendDataAsLast
{
    [self sendInternal];
}

- (void)disconnect
{
    if (self.state == state_connected) {
        self.state = state_closing;
        [self.session unsubscribeTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"subscription_preference"]];
        [self.session close];
    } else {
        self.state = state_starting;
        NSLog(@"MQTTitude not connected, can't close");
        
    }
}

- (void)stop
{
    [self disconnect];
    self.state = state_exit;
}

- (void)subscribe:(NSString *)topic qos:(NSInteger)qos
{
    [self.session subscribeToTopic:topic atLevel:qos];
}

- (void)unsubscribe:(NSString *)topic
{
    [self.session unsubscribeTopic:topic];
}

#pragma mark - MQtt Callback methods


- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode
{
#ifdef DEBUG
    NSLog(@"MQTTitude eventCode: %d", eventCode);
#endif
    [self.reconnectTimer invalidate];
    switch (eventCode) {
        case MQTTSessionEventConnected:
        {
            self.state = state_connected;
            [self.session subscribeToTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"subscription_preference"]
                                   atLevel:[[NSUserDefaults standardUserDefaults] integerForKey:@"subscriptionqos_preference"]];
            while ([self.fifo count]) {
                /*
                 * if there are some queued send messages, send them
                 */
                NSDictionary *parameters = self.fifo[0];
                [self.fifo removeObjectAtIndex:0];
                [self sendData:parameters[@"DATA"] topic:parameters[@"TOPIC"] qos:[parameters[@"QOS"] intValue] retain:[parameters[@"RETAINFLAG"] boolValue]];
            }
            break;
            self.state = state_error;
            break;
        }
        case MQTTSessionEventConnectionClosed:
            self.state = state_starting;
            break;
        case MQTTSessionEventProtocolError:
        case MQTTSessionEventConnectionRefused:
        case MQTTSessionEventConnectionError:
        {
#ifdef DEBUG
            NSLog(@"reconnect after: %f", self.reconnectTime);
#endif
            self.reconnectTimer = [NSTimer timerWithTimeInterval:self.reconnectTime
                                                          target:self
                                                        selector:@selector(reconnect)
                                                        userInfo:Nil repeats:FALSE];
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:self.reconnectTimer
                      forMode:NSDefaultRunLoopMode];
            
            break;
        }
        default:
            NSLog(@"MQTTitude unknown eventCode: %d", eventCode);
            self.state = state_exit;
            break;
    }
}

/*
 * Incoming Data Handler for subscriptions
 *
 * all incoming data is responded to by a publish of the current position
 *
 */

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic
{
#ifdef DEBUG
    NSLog(@"Received %@ %@", topic, [Connection dataToString:data]);
#endif
    [self.delegate handleMessage:data onTopic:topic];
}

- (void)lowlevellog:(MQTTSession *)session component:(NSString *)component message:(NSString *)message mqttmsg:(MQTTMessage *)mqttmsg
{
    [self.delegate lowlevellog:session component:component message:message mqttmsg:mqttmsg];
}

- (void)connectToInternal
{
    if (self.state == state_starting) {
        self.state = state_connecting;
        
        self.session = [[MQTTSession alloc] initWithClientId:[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                                    userName:self.lastAuth ? self.lastUser : @""
                                                    password:self.lastAuth ? self.lastPass : @""
                                                   keepAlive:self.lastKeepalive
                                                cleanSession:self.lastClean
                                                   willTopic:self.lastWillTopic
                                                     willMsg:self.lastWill
                                                     willQoS:self.lastWillQos
                                              willRetainFlag:self.lastWillRetainFlag
                                                     runLoop:[NSRunLoop currentRunLoop]
                                                     forMode:NSDefaultRunLoopMode];
        [self.session setDelegate:self];
        [self.session connectToHost:self.lastHost
                               port:self.lastPort
                           usingSSL:self.lastTls];
    } else {
        NSLog(@"MQTTitude not starting, can't connect");
    }
}



- (void)sendInternal
{    
    if (self.state != state_connected) {
#ifdef DEBUG
        NSLog(@"into fifo");
#endif
        NSDictionary *parameters = @{
                                     @"DATA": self.lastData,
                                     @"TOPIC": self.lastTopic,
                                     @"QOS": [NSString stringWithFormat:@"%d",  self.lastQos],
                                     @"RETAINFLAG": [NSString stringWithFormat:@"%d",  self.lastRetainFlag]
                                     };
        [self.fifo addObject:parameters];
        [self connectToLast];
    } else {
#ifdef DEBUG
        NSLog(@"Sending: %@", [Connection dataToString:self.lastData]);
#endif
        [self.session publishData:self.lastData
                          onTopic:self.lastTopic
                           retain:self.lastRetainFlag
                              qos:self.lastQos];
    }
}

+ (NSString *)dataToString:(NSData *)data
{
    /* the following lines are necessary to convert data which is possibly not null-terminated into a string */
    NSString *message = [[NSString alloc] init];
    for (int i = 0; i < data.length; i++) {
        char c;
        [data getBytes:&c range:NSMakeRange(i, 1)];
        message = [message stringByAppendingFormat:@"%c", c];
    }
    return message;
}



@end
