//
//  mqttitudeCoreData.m
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeCoreData.h"

@interface mqttitudeCoreData()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

static NSManagedObjectContext *theManagedObjectContext = nil;

@implementation mqttitudeCoreData

- (void)useDocument
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"MQTTitude"];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        NSLog(@"Document creation %@\n", [url path]);
        [self.document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            if (success) {
                NSLog(@"Document created %@\n", [url path]);
                self.managedObjectContext = self.document.managedObjectContext;
            }
        }];
    } else if (self.document.documentState == UIDocumentStateClosed) {
        NSLog(@"Document opening %@\n", [url path]);
        [self.document openWithCompletionHandler:^(BOOL success){
            if (success) {
                NSLog(@"Document opened %@\n", [url path]);
                self.managedObjectContext = self.document.managedObjectContext;
            }
        }];
    } else {
        NSLog(@"Document used %@\n", [url path]);
        self.managedObjectContext = self.document.managedObjectContext;
    }
}


+ (NSManagedObjectContext *)theManagedObjectContext
{
    return theManagedObjectContext;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    theManagedObjectContext = managedObjectContext;
}


@end
