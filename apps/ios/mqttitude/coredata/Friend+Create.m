//
//  Friend+Create.m
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Friend+Create.h"
#import "Location+Create.h"

@implementation Friend (Create)

+ (ABAddressBookRef)theABRef
{
    static ABAddressBookRef ab = nil;
    static BOOL isGranted = YES;
    
    if (!ab) {
        if (isGranted) {
#ifdef DEBUG
            NSLog(@"ABAddressBookCreateWithOptions");
#endif
            CFErrorRef cfError;
            ab = ABAddressBookCreateWithOptions(NULL, &cfError);
            if (!ab) {
                CFStringRef errorDescription = CFErrorCopyDescription(cfError);
                [Friend error:[NSString stringWithFormat:@"ABAddressBookCreateWithOptions not successfull %@", errorDescription]];
                CFRelease(errorDescription);
                isGranted = NO;
            }
        }
    }
    return ab;
}

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
            friend.abRecordId = @(kABRecordInvalidID);
            friend.hasLocations = [[NSSet alloc] init];
        } else {
            // friend exists already
            friend = [matches lastObject];
        }
    }
    
    return friend;
}

- (NSString *)name
{
    ABRecordRef record = [self recordOfFriend];
    
    if (record) {
        return [Friend nameOfPerson:record];
    } else {
        return nil;
    }
}

- (NSData *)image
{
    ABRecordRef record = [self recordOfFriend];
    
    if (record) {
        return [Friend imageDataOfPerson:record];
    } else {
       return nil;
    }
}

- (ABRecordRef)recordOfFriend
{
    ABRecordRef recordDirect = NULL;
    ABRecordRef recordViaTopic = NULL;

#ifdef DEBUG
    NSLog(@"Friend abRecordId =  %d", [self.abRecordId intValue]);
#endif

    if ([self.abRecordId intValue] != kABRecordInvalidID) {
        recordDirect = ABAddressBookGetPersonWithRecordID([Friend theABRef],
                                                   [self.abRecordId intValue]);
#ifdef DEBUG
        NSLog(@"Friend ABRecordRef by abRecordID =  %p", recordDirect);
#endif
    }
    
    recordViaTopic = recordWithTopic((__bridge CFStringRef)(self.topic));
#ifdef DEBUG
    NSLog(@"Friend ABRecordRef by topic =  %p", recordViaTopic);
#endif

    if (recordDirect) {
        if (recordViaTopic) {
            if (recordDirect == recordViaTopic) {
                return recordDirect;
            } else {
                [self linkToAB:recordViaTopic];
                return recordViaTopic;
            }
        } else {
            [self linkToAB:recordDirect];
            return recordDirect;
        }
    } else {
        if (recordViaTopic) {
                [self linkToAB:recordViaTopic];
        }
        return recordDirect;
    }
}

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

- (void)linkToAB:(ABRecordRef)record
{
    ABRecordID abRecordID = ABRecordGetRecordID(record);
    self.abRecordId = @(abRecordID);

    ABRecordRef oldrecord = recordWithTopic((__bridge CFStringRef)(self.topic));
    
    if (oldrecord) {
        [self ABsetTopic:nil record:oldrecord];
    }
    
    [self ABsetTopic:self.topic record:record];
    
    // make sure all locations are updated so all views get updated
    for (Location *location in self.hasLocations) {
        location.belongsTo = self;
    }
}

#define RELATION_NAME CFSTR("MQTTitude")

ABRecordRef recordWithTopic(CFStringRef topic)
{
    ABRecordRef theRecord = NULL;
    
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople([Friend theABRef]);
    
    for (CFIndex i = 0; i < CFArrayGetCount(records); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        
        ABMultiValueRef relations = ABRecordCopyValue(record, kABPersonRelatedNamesProperty);
        if (relations) {
            CFIndex relationsCount = ABMultiValueGetCount(relations);
            
            for (CFIndex k = 0 ; k < relationsCount ; k++) {
                CFStringRef label = ABMultiValueCopyLabelAtIndex(relations, k);
                CFStringRef value = ABMultiValueCopyValueAtIndex(relations, k);
                if(CFStringCompare(label, RELATION_NAME, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                    if(CFStringCompare(value, topic, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        theRecord = record;
                        CFRelease(label);
                        CFRelease(value);
                        break;
                    }
                }
                CFRelease(label);
                CFRelease(value);
            }
            CFRelease(relations);
        }
    }
    CFRelease(records);
    return theRecord;
}

- (void)ABsetTopic:(NSString *)topic record:(ABRecordRef)record
{
    
    CFErrorRef errorRef;

    ABMutableMultiValueRef relationsRW;
    
    ABMultiValueRef relationsRO = ABRecordCopyValue(record, kABPersonRelatedNamesProperty);
    
    if (relationsRO) {
        relationsRW = ABMultiValueCreateMutableCopy(relationsRO);
        CFRelease(relationsRO);
    } else {
        relationsRW = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    }
    
    CFIndex relationsCount = ABMultiValueGetCount(relationsRW);
    CFIndex i;
    
    for (i = 0 ; i < relationsCount ; i++) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(relationsRW, i);
        if(CFStringCompare(label, RELATION_NAME, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
            if (topic) {
                if (!ABMultiValueReplaceValueAtIndex(relationsRW, (__bridge CFTypeRef)(topic), i)) {
                    [Friend error:[NSString stringWithFormat:@"Friend error ABMultiValueReplaceValueAtIndex %@ %ld", topic, i]];
                }
            } else {
                if (!ABMultiValueRemoveValueAndLabelAtIndex(relationsRW, i))  {
                    [Friend error:[NSString stringWithFormat:@"Friend error ABMultiValueRemoveValueAndLabelAtIndex %ld", i]];
                }
            }
            CFRelease(label);
            break;
        }
        CFRelease(label);
    }
    if (i == relationsCount) {
        if (topic) {
            if (!ABMultiValueAddValueAndLabel(relationsRW, (__bridge CFStringRef)(self.topic), RELATION_NAME, NULL)) {
                [Friend error:[NSString stringWithFormat:@"Friend error ABMultiValueAddValueAndLabel %@ %@", topic, RELATION_NAME]];
            }
        }
    }
        
    if (!ABRecordSetValue(record, kABPersonRelatedNamesProperty, relationsRW, &errorRef)) {
        [Friend error:[NSString stringWithFormat:@"Friend error ABRecordSetValue %@", errorRef]];
    }
    CFRelease(relationsRW);
    
    if (ABAddressBookHasUnsavedChanges([Friend theABRef])) {
        if (!ABAddressBookSave([Friend theABRef], &errorRef)) {
            [Friend error:[NSString stringWithFormat:@"Friend error ABAddressBookSave %@", errorRef]];
        }
    }
}

+ (void)error:(NSString *)message
{
#ifdef DEBUG
    NSLog(@"Friend error %@", message);
#endif
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSBundle mainBundle].infoDictionary[@"CFBundleName"]
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [alertView show];
    
}

@end
