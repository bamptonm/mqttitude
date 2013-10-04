//
//  Friend+Create.m
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Friend+Create.h"
#import <AddressBook/AddressBook.h>

static ABAddressBookRef ab = nil;
static BOOL isGranted = YES;

@implementation Friend (Create)
+ (Friend *)friendWithTopic:(NSString *)topic
     inManagedObjectContext:(NSManagedObjectContext *)context

{
    Friend *friend = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Friend"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"topic" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"topic = %@", topic];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || [matches count] > 1) {
        // handle error
    } else {
        
        if (![matches count]) {
            //create new friend
            friend = [NSEntityDescription insertNewObjectForEntityForName:@"Friend" inManagedObjectContext:context];
            
            friend.topic = topic;
            
            friend.device = nil;
            friend.hasLocations = [[NSSet alloc] init];
        } else {
            // friend exists already
            friend = [matches lastObject];
        }
        [friend refreshFromAB];
    }
    
    return friend;

}

- (void)refreshFromAB
{
    ABRecordRef record = recordWithTopic((__bridge CFStringRef)(self.topic));
    if (record) {
        self.name = [Friend nameOfPerson:record];
        self.image = [Friend imageDataOfPerson:record];
    }
}

#define SERVICE_NAME CFSTR("MQTTitude")
#define RELATION_NAME CFSTR("MQTTitude")

+ (NSString *)nameOfPerson:(ABRecordRef)record
{
    NSString *name;
    name =  CFBridgingRelease(ABRecordCopyValue(record, kABPersonNicknameProperty));
    if (!name) {
        name = CFBridgingRelease(ABRecordCopyCompositeName(record));
    }
    return name;
}

+ (NSData *)imageDataOfPerson:(ABRecordRef)record
{
    NSData *imageData = nil;
    
    if (ABPersonHasImageData(record)) {
        CFDataRef ir = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
        imageData = CFBridgingRelease(ir);
    }
    return imageData;
}

ABRecordRef recordWithTopic(CFStringRef topic)
{
    // Address Book
    if (!ab) {
        if (!isGranted) {
            return nil;
        } else {
#ifdef DEBUG
            NSLog(@"ABAddressBookCreateWithOptions");
#endif
            CFErrorRef error;
            ab = ABAddressBookCreateWithOptions(NULL, &error);
            if (!ab) {
                NSLog(@"ABAddressBookCreateWithOptions not successfull %@", CFErrorCopyDescription(error));
                isGranted = NO;
                return nil;
            }
        }
    }
    
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(ab);
    
    for (CFIndex i = 0; i < CFArrayGetCount(records); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        
        /*
         * Social Services (not supported by all address books
         */
        
        ABMultiValueRef socials = ABRecordCopyValue(record, kABPersonSocialProfileProperty);
        if (socials) {
            CFIndex socialsCount = ABMultiValueGetCount(socials);
            
            for (CFIndex k = 0 ; k < socialsCount ; k++) {
                CFDictionaryRef socialValue = ABMultiValueCopyValueAtIndex(socials, k);
                
                if(CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileServiceKey), SERVICE_NAME, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                    if (CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey), topic, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        CFRelease(socialValue);
                        CFRelease(socials);
                        return record;
                    }
                }
                CFRelease(socialValue);
            }
            CFRelease(socials);
        }
        
        /*
         * Relations (family)
         */
        
        ABMultiValueRef relations = ABRecordCopyValue(record, kABPersonRelatedNamesProperty);
        if (relations) {
            CFIndex relationsCount = ABMultiValueGetCount(relations);
            
            for (CFIndex k = 0 ; k < relationsCount ; k++) {
                CFStringRef label = ABMultiValueCopyLabelAtIndex(relations, k);
                CFStringRef value = ABMultiValueCopyValueAtIndex(relations, k);
                if(CFStringCompare(label, RELATION_NAME, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                    if(CFStringCompare(value, topic, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        CFRelease(relations);
                        return record;
                    }
                }
            }
            CFRelease(relations);
        }
        
        CFRelease(record);
    }
    return nil;
}


@end
