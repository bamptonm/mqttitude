//
//  Logs.h
//  mqttitude
//
//  Created by Christoph Krey on 20.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Logs;

@protocol LogsDelegate <NSObject>
- (void)changed:(Logs *)logs;
- (void)insert:(Logs *)logs at:(NSInteger)pos;
- (void)remove:(Logs *)logs at:(NSInteger)pos;
@end


@interface Logs : NSObject
@property (weak, nonatomic) id<LogsDelegate> delegate;
- (Logs *)initWithName:(NSString *)name;
- (void)log:(NSString *)message;
- (NSString *)elementAtPosition:(NSInteger)pos;
- (NSInteger)count;
@end
