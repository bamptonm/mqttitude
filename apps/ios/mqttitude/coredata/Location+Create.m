//
//  Location+Create.m
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Location+Create.h"
#import <AddressBookUI/AddressBookUI.h>
#import "Friend+Create.h"

@implementation Location (Create)
+ (Location *)locationWithTopic:(NSString *)topic
                      timestamp:(NSDate *)timestamp
                     coordinate:(CLLocationCoordinate2D)coordinate
                       accuracy:(CLLocationAccuracy)accuracy
                      automatic:(BOOL)automatic
                      remark:(NSString *)remark
                      radius:(CLLocationDistance)radius
         inManagedObjectContext:(NSManagedObjectContext *)context;
{
    Location *location = nil;
    
    Friend *friend = [Friend friendWithTopic:topic inManagedObjectContext:context];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    request.predicate = [NSPredicate predicateWithFormat:@"timestamp = %@ AND belongsTo = %@", timestamp, friend];

    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if (![matches count]) {
            //create new location
            location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
            
            location.belongsTo = friend;
            location.timestamp = timestamp;
            [location setCoordinate:coordinate];
            location.accuracy = @(accuracy);
            location.automatic = @(automatic);
        } else {
            location = [matches lastObject];
        }
    }
    
    return location;
}

+ (NSArray *)allLocationsInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    return matches;
}

+ (NSArray *)allOverlaysInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    request.predicate = [NSPredicate predicateWithFormat:@"automatic = 0"];

    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    return matches;
}

+ (NSArray *)allLocationsWithFriend:(Friend *)friend inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    request.predicate = [NSPredicate predicateWithFormat:@"belongsTo = %@ AND automatic = 1", friend];

    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    return matches;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.title, self.subtitle];
}

- (NSString *)title {
    return [NSString stringWithFormat:@"%@", [self nameText]];
}

- (NSString *)subtitle {
    return [NSString stringWithFormat:@"%@ %@",
            [NSDateFormatter localizedStringFromDate:self.timestamp
                                           dateStyle:NSDateFormatterShortStyle
                                           timeStyle:NSDateFormatterShortStyle],
            [self locationText]];
}

- (NSString *)nameText
{
    return self.belongsTo ? (self.belongsTo.name ? self.belongsTo.name : self.belongsTo.topic) : @"";
}
- (NSString *)timestampText
{
    return [NSDateFormatter localizedStringFromDate:self.timestamp
                                          dateStyle:NSDateFormatterShortStyle
                                          timeStyle:NSDateFormatterMediumStyle];
}
- (NSString *)locationText
{
    return [NSString stringWithFormat:@"%@ (±%.0fm)",
            (self.placemark) ? self.placemark :
            [NSString stringWithFormat:@"%f,%f", self.coordinate.latitude, self.coordinate.longitude],
            [self.accuracy doubleValue]];
}

- (NSString *)coordinateText
{
    return [NSString stringWithFormat:@"%f,%f (±%.0fm)",
            self.coordinate.latitude,
            self.coordinate.longitude,
            [self.accuracy doubleValue]];
}

- (NSString *)radiusText
{
    return [NSString stringWithFormat:@"%.0f", self.radius];
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
    return coord;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    self.latitude = @(coordinate.latitude);
    self.longitude = @(coordinate.longitude);
    
    /*
     * We could get the Reverse GeoCode here automatically, but this would cost mobile data. If necessary, call getReverseGeoCode directly for actually shown locations
     *
     [self getReversGeoCode];
     *
     */
}


- (void)getReverseGeoCode
{
    if (!self.placemark) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:0 timestamp:0];
        [geocoder reverseGeocodeLocation:location completionHandler:
         ^(NSArray *placemarks, NSError *error) {
             if ([placemarks count] > 0) {
                 CLPlacemark *placemark = placemarks[0];
                 self.placemark = ABCreateStringWithAddressDictionary (placemark.addressDictionary, TRUE);
                 self.placemark = [self.placemark stringByReplacingOccurrencesOfString:@"\n" withString:@", "];
             } else {
                 self.placemark = nil;
             }
         }];
    }
}

- (CLRegion *)region
{
    CLRegion *region = nil;
    if (![self.automatic boolValue] && self.remark && self.radius > 0) {
        region = [[CLRegion alloc] initCircularRegionWithCenter:self.coordinate
                                                         radius:self.radius
                                                     identifier:self.remark];
    }
    return region;
}

- (MKMapRect)boundingMapRect
{
    return [MKCircle circleWithCenterCoordinate:self.coordinate radius:self.radius].boundingMapRect;
}

- (CLLocationDistance)radius
{
    return [self.regionradius doubleValue];
}

@end
