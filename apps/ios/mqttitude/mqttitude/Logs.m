//
//  Logs.m
//  mqttitude
//
//  Created by Christoph Krey on 20.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Logs.h"

@interface Logs()
@property (strong, nonatomic) NSMutableArray *logArray;
@end

@implementation Logs

- (NSMutableArray *)logArray
{
    if (!_logArray) {
        _logArray = [[NSMutableArray alloc] init];
    }
    return _logArray;
}

- (NSString *)elementAtPosition:(NSInteger)pos
{
    if (pos > [self count]) {
        return nil;
    } else {
        return self.logArray[pos];
    }
}

#define MAX_LOGS 256

- (void)log:(NSString *)message
{
    NSString *logEntry = [NSString stringWithFormat:@"%@: %@", [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                                              dateStyle:NSDateFormatterShortStyle
                                                                                              timeStyle:NSDateFormatterMediumStyle], message];
    [self.logArray insertObject:logEntry atIndex:0];
    [self.delegate insert:self at:0];
    if ([self.logArray count] > MAX_LOGS) {
        [self.logArray removeLastObject];
        [self.delegate remove:self at:MAX_LOGS];
    }
    [self.delegate changed:self];
}

- (NSInteger)count
{
    return [self.logArray count];
}
@end
