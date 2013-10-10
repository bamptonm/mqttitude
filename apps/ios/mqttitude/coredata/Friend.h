//
//  Friend.h
//  mqttitude
//
//  Created by Christoph Krey on 10.10.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Friend : NSManagedObject

@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSSet *hasLocations;
@end

@interface Friend (CoreDataGeneratedAccessors)

- (void)addHasLocationsObject:(Location *)value;
- (void)removeHasLocationsObject:(Location *)value;
- (void)addHasLocations:(NSSet *)values;
- (void)removeHasLocations:(NSSet *)values;

@end
