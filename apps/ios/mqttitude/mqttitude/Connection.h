//
//  Connection.h
//  mqttitude
//
//  Created by Christoph Krey on 25.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTSession.h"


@protocol ConnectionDelegate <NSObject>

enum state {
    state_starting,
    state_connecting,
    state_error,
    state_connected,
    state_closing,
    state_closed
};

- (void)showState:(NSInteger)state;
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic;

@end

@interface Connection: NSObject <MQTTSessionDelegate>

@property (weak, nonatomic) id<ConnectionDelegate> delegate;
@property (nonatomic, readonly) NSInteger state;
@property (nonatomic, readonly) NSDate *lastConnected;
@property (nonatomic, readonly) NSDate *lastClosed;
@property (nonatomic, readonly) NSDate *lastError;
@property (nonatomic, readonly) NSError *lastErrorCode;

- (void)connectTo:(NSString *)host port:(NSInteger)port tls:(BOOL)tls keepalive:(NSInteger)keepalive auth:(BOOL)auth user:(NSString *)user pass:(NSString *)pass willTopic:(NSString *)willTopic will:(NSData *)will willQos:(NSInteger)willQos willRetainFlag:(BOOL)willRetainFlag;
- (void)sendData:(NSData *)data topic:(NSString *)topic qos:(NSInteger)qos retain:(BOOL)retainFlag;
- (void)subscribe:(NSString *)topic qos:(NSInteger)qos;
- (void)unsubscribe:(NSString *)topic;
- (void)disconnect;

- (NSString *)url;
+ (NSString *)dataToString:(NSData *)data;

@end
