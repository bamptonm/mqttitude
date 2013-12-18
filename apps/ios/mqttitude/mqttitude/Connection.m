//
//  Connection.m
//  mqttitude
//
//  Created by Christoph Krey on 25.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Connection.h"
#import "Publication+Create.h"
#import "mqttitudeCoreData.h"

@interface Connection()

@property (nonatomic) NSInteger state;

@property (strong, nonatomic) NSTimer *reconnectTimer;
@property (nonatomic) double reconnectTime;
@property (nonatomic) BOOL reconnectFlag;

@property (strong, nonatomic) MQTTSession *session;

@property (strong, nonatomic) NSString *lastClientId;
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

@property (nonatomic, readwrite) NSError *lastErrorCode;

@end

#define RECONNECT_TIMER 1.0
#define RECONNECT_TIMER_MAX 64.0

@implementation Connection

- (id)init
{
#ifdef DEBUG
    NSLog(@"Connection init");
#endif

    self = [super init];
    self.state = state_starting;
    return self;
}

/*
 * externally visible methods
 */

- (void)connectTo:(NSString *)host
             port:(NSInteger)port
              tls:(BOOL)tls
        keepalive:(NSInteger)keepalive
            clean:(BOOL)clean
             auth:(BOOL)auth
             user:(NSString *)user
             pass:(NSString *)pass
        willTopic:(NSString *)willTopic
             will:(NSData *)will
          willQos:(NSInteger)willQos
   willRetainFlag:(BOOL)willRetainFlag
     withClientId:(NSString *)clientId
{
#ifdef DEBUG
    NSLog(@"Connection connectTo: %@:%@@%@:%d %@ (%d) c%d / %@ %@ q%d r%d as %@",
          auth ? user : @"",
          auth ? pass : @"",
          host,
          port,
          tls ? @"TLS" : @"PLAIN",
          keepalive,
          clean,
          willTopic,
          [Connection dataToString:will],
          willQos,
          willRetainFlag,
          clientId
          );
#endif

    self.lastHost = host;
    self.lastPort = port;
    self.lastTls = tls;
    self.lastKeepalive = keepalive;
    self.lastClean = clean;
    self.lastAuth = auth;
    self.lastUser = user;
    self.lastPass = pass;
    self.lastWillTopic = willTopic;
    self.lastWill = will;
    self.lastWillQos = willQos;
    self.lastWillRetainFlag = willRetainFlag;
    self.lastClientId = clientId;
    
    self.reconnectTime = RECONNECT_TIMER;
    self.reconnectFlag = FALSE;
    
    [self connectToInternal];
}

- (long)sendData:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos retain:(BOOL)retainFlag
{
#ifdef DEBUG
    NSLog(@"Connection sendData:%@ %@ q%d r%d", topic, [Connection dataToString:data], qos, retainFlag);
#endif

    long longMsgID = -1;
    
    if (self.state != state_connected) {
#ifdef DEBUG
        NSLog(@"Connection intoFifo");
#endif
        [Publication publicationWithTimestamp:[NSDate date]
                                        msgID:@(-1)
                                        topic:topic
                                         data:data qos:@(qos)
                                   retainFlag:@(retainFlag)
                       inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
        [self.delegate fifoChanged:[mqttitudeCoreData theManagedObjectContext]];
        [self connectToLast];
    } else {
#ifdef DEBUG
        NSLog(@"Connection send");
#endif
        UInt16 msgID = [self.session publishData:data
                                         onTopic:topic
                                          retain:retainFlag
                                             qos:qos];
        if (msgID) {
            [Publication publicationWithTimestamp:[NSDate date]
                                            msgID:[NSNumber numberWithUnsignedInt:msgID]
                                            topic:topic
                                             data:data
                                              qos:@(qos)
                                       retainFlag:@(retainFlag)
                           inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
            [self.delegate fifoChanged:[mqttitudeCoreData theManagedObjectContext]];
        }
        longMsgID = msgID;
    }
    if ([self.delegate respondsToSelector:@selector(saveContext)]) {
        [self.delegate performSelector:@selector(saveContext)];
    }
    return longMsgID;
}

- (void)disconnect
{
#ifdef DEBUG
    NSLog(@"Connection disconnect:");
#endif

    if (self.state == state_connected) {
        self.state = state_closing;
        [self.session close];
    } else {
        self.state = state_starting;
        NSLog(@"Connection not connected, can't close");
        if (self.reconnectTimer) {
            [self.reconnectTimer invalidate];
            self.reconnectTimer = nil;
        }
    }
}

- (void)subscribe:(NSString *)topic qos:(NSInteger)qos
{
#ifdef DEBUG
    NSLog(@"Connection subscribe:%@ (%d)", topic, qos);
#endif

    [self.session subscribeToTopic:topic atLevel:qos];
}

- (void)unsubscribe:(NSString *)topic
{
#ifdef DEBUG
    NSLog(@"Connection unsubscribe:%@", topic);
#endif

    [self.session unsubscribeTopic:topic];
}

#pragma mark - MQtt Callback methods

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
#ifdef DEBUG
    const NSDictionary *events = @{
                                   @(MQTTSessionEventConnected): @"connected",
                                   @(MQTTSessionEventConnectionRefused): @"connection refused",
                                   @(MQTTSessionEventConnectionClosed): @"connection closed",
                                   @(MQTTSessionEventConnectionError): @"connection error",
                                   @(MQTTSessionEventProtocolError): @"protocoll error"
                                   };
    NSLog(@"Connection MQTT eventCode: %@ (%d) %@", events[@(eventCode)], eventCode, error);
#endif
    [self.reconnectTimer invalidate];
    switch (eventCode) {
        case MQTTSessionEventConnected:
        {
            self.lastErrorCode = nil;
            self.state = state_connected;
            
            /*
             * if there are some unacknowledged send messages in non-clean-session-mode, re-send them
             */

            if (self.lastClean) {
                [Publication cleanPublications:[mqttitudeCoreData theManagedObjectContext]];
                [self.delegate fifoChanged:[mqttitudeCoreData theManagedObjectContext]];
            } else {
                NSArray *publications = [Publication unacknowledgedPublications:[mqttitudeCoreData theManagedObjectContext]];
                for (Publication *publication in publications) {
                    [self sendData:publication.data topic:publication.topic qos:[publication.qos integerValue] retain:[publication.retainFlag boolValue]];
                    [self.delegate fifoChanged:[mqttitudeCoreData theManagedObjectContext]];
                }
            }
            
            /*
             * if there are some queued send messages never sent before, send them
             */
            Publication *publication;
            while ((publication = [Publication publicationWithmsgID:@(-1) inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]])) {
                
                [self sendData:publication.data topic:publication.topic qos:[publication.qos integerValue] retain:[publication.retainFlag boolValue]];
                [[mqttitudeCoreData theManagedObjectContext] deleteObject:publication];
                [self.delegate fifoChanged:[mqttitudeCoreData theManagedObjectContext]];
            }
            
            /*
             * if clean-session is set or if it's the first time we connect in non-clean-session-mode, subscribe to topic
             */
            if (self.lastClean || !self.reconnectFlag) {
                [self.session subscribeToTopic:[[NSUserDefaults standardUserDefaults] stringForKey:@"subscription_preference"]
                                       atLevel:[[NSUserDefaults standardUserDefaults] integerForKey:@"subscriptionqos_preference"]];
                self.reconnectFlag = TRUE;
            }

            break;
        }
        case MQTTSessionEventConnectionClosed:
            /* this informs the caller that the connection is closed
             * specifically, the caller can end the background task now */
            self.state = state_closed;
            self.state = state_starting;
            break;
        case MQTTSessionEventProtocolError:
        case MQTTSessionEventConnectionRefused:
        case MQTTSessionEventConnectionError:
        {
#ifdef DEBUG
            NSLog(@"Connection setTimer %f", self.reconnectTime);
#endif
            self.reconnectTimer = [NSTimer timerWithTimeInterval:self.reconnectTime
                                                          target:self
                                                        selector:@selector(reconnect)
                                                        userInfo:Nil repeats:FALSE];
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:self.reconnectTimer
                      forMode:NSDefaultRunLoopMode];
            
            self.state = state_error;
            self.lastErrorCode = error;
            break;
        }
        default:
            break;
    }
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    Publication *publication = [Publication publicationWithmsgID:[NSNumber numberWithUnsignedInt:msgID] inManagedObjectContext:[mqttitudeCoreData theManagedObjectContext]];
    if (publication) {
        [self.delegate messageDelivered:msgID timestamp:publication.timestamp topic:publication.topic data:publication.data];
        [[mqttitudeCoreData theManagedObjectContext] deleteObject:publication];
    }
    [self.delegate fifoChanged:[mqttitudeCoreData theManagedObjectContext]];
    if ([self.delegate respondsToSelector:@selector(saveContext)]) {
        [self.delegate performSelector:@selector(saveContext)];
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
    NSLog(@"Connection received %@ %@", topic, [Connection dataToString:data]);
#endif
    [self.delegate handleMessage:data onTopic:topic];
    if ([self.delegate respondsToSelector:@selector(saveContext)]) {
        [self.delegate performSelector:@selector(saveContext)];
    }
}

#pragma internal helpers

- (void)connectToInternal
{
    if (self.state == state_starting) {
        self.state = state_connecting;
                
        self.session = [[MQTTSession alloc] initWithClientId:self.lastClientId
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
        NSLog(@"Connection not starting, can't connect");
    }
}

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@%@:%d",
            self.lastAuth ? [NSString stringWithFormat:@"%@@", self.lastUser] : @"",
            self.lastHost,
            self.lastPort
            ];
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

- (void)setState:(NSInteger)state
{
    _state = state;
#ifdef DEBUG
    const NSDictionary *states = @{
                                   @(state_starting): @"starting",
                                   @(state_connecting): @"connecting",
                                   @(state_error): @"error",
                                   @(state_connected): @"connected",
                                   @(state_closing): @"closing",
                                   @(state_closed): @"closed"
                                   };
    
    NSLog(@"Connection state %@ (%d)", states[@(self.state)], self.state);
#endif
    [self.delegate showState:self.state];
}

- (void)reconnect
{
#ifdef DEBUG
    NSLog(@"Connection reconnect");
#endif
    
    self.reconnectTimer = nil;
    self.state = state_starting;

    if (self.reconnectTime < RECONNECT_TIMER_MAX) {
        self.reconnectTime *= 2;

    }
    
    [self connectToInternal];

}

- (void)connectToLast
{
#ifdef DEBUG
    NSLog(@"Connection connectToLast");
#endif
    
    self.reconnectTime = RECONNECT_TIMER;
    
    [self connectToInternal];
}

@end
