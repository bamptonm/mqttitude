//
//  Publication.h
//  mqttitude
//
//  Created by Christoph Krey on 27.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Publication : NSManagedObject

@property (nonatomic, retain) NSNumber * msgID;
@property (nonatomic, retain) NSNumber * qos;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSNumber * retainFlag;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSDate * timestamp;

@end
