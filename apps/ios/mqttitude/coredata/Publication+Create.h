//
//  Publication+Create.h
//  mqttitude
//
//  Created by Christoph Krey on 27.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Publication.h"

@interface Publication (Create)
+ (Publication *)publicationWithTimestamp:(NSDate *)timestamp
                                     msgID:(NSNumber *)msgID
                                     topic:(NSString *)topic
                                      data:(NSData *)data
                                       qos:(NSNumber *)qos
                                retainFlag:(NSNumber *)retainFlag
                   inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Publication *)publicationWithmsgID:(NSNumber *)msgID
               inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSInteger)countPublications:(NSManagedObjectContext *)context;
+ (void)cleanPublications:(NSManagedObjectContext *)context;
+ (NSArray *)unacknowledgedPublications:(NSManagedObjectContext *)context;

@end
