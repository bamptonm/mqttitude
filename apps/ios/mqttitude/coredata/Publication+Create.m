//
//  Publication+Create.m
//  mqttitude
//
//  Created by Christoph Krey on 27.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Publication+Create.h"

@implementation Publication (Create)

+ (Publication *)publicationWithTimestamp:(NSDate *)timestamp
                                    msgID:(NSNumber *)msgID
                                    topic:(NSString *)topic
                                     data:(NSData *)data
                                      qos:(NSNumber *)qos
                               retainFlag:(NSNumber *)retainFlag
                   inManagedObjectContext:(NSManagedObjectContext *)context

{
    
#ifdef DEBUG
    NSLog(@"publicationWithTimestamp %@ %f", msgID, [timestamp timeIntervalSince1970]);
#endif

    Publication *publication = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Publication"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"timestamp = %@", timestamp];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
#ifdef DEBUG
    NSLog(@"publicationWithTimestamp count %d", [matches count]);
#endif

    if (!matches || [matches count] > 1) {
        // handle error
    } else if (![matches count]) {
        //create new publication
        publication = [NSEntityDescription insertNewObjectForEntityForName:@"Publication" inManagedObjectContext:context];
        
        publication.timestamp = timestamp;
        
        publication.msgID = msgID;
        publication.topic = topic;
        publication.data = data;
        publication.qos = qos;
        publication.retainFlag = retainFlag;
    } else {
        // publication exists already
        publication = [matches lastObject];
    }
    
    return publication;
}

+ (Publication *)publicationWithmsgID:(NSNumber *)msgID
               inManagedObjectContext:(NSManagedObjectContext *)context

{
#ifdef DEBUG
    NSLog(@"publicationWithmsgID %@", msgID);
#endif

    Publication *publication = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Publication"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"msgID" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"msgID = %@", msgID];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
#ifdef DEBUG
    NSLog(@"publicationWithmsgID count %d", [matches count]);
#endif

    if (matches && [matches count]) {
        publication = [matches lastObject];
    }
    
    return publication;
}

+ (NSInteger)countPublications:(NSManagedObjectContext *)context
{
    NSInteger count = 0;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Publication"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (matches) {
        count = [matches count];
#ifdef DEBUG
        NSLog(@"countPublications count %d", [matches count]);
        for (Publication *publication in matches) {
            NSLog(@"countPublications %d %@", [publication.msgID intValue], publication.timestamp);
        }
#endif

    }
    
    return count;
}

+ (void)cleanPublications:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Publication"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"msgID > 0"];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    for (id object in matches) {
        [context deleteObject:object];
    }
}

+ (NSArray *)unacknowledgedPublications:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Publication"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"msgID > 0"];
    
    NSError *error = nil;
    
    NSArray *publications = [context executeFetchRequest:request error:&error];
#ifdef DEBUG
    for (Publication *publication in publications) {
        NSLog(@"Publication %u %@", [publication.msgID intValue], publication.timestamp);
    }
#endif
    return publications;
}

@end
