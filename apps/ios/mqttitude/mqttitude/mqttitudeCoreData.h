//
//  mqttitudeCoreData.h
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface mqttitudeCoreData : NSObject
@property (strong, nonatomic) UIManagedDocument *document;
+ (NSManagedObjectContext *)theManagedObjectContext;
- (void)useDocument;
@end
