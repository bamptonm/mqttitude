//
//  Annotation.
//  MQTTitude
//
//  Created by Christoph Krey on 13.07.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Annotation.h"
#import <AddressBookUI/AddressBookUI.h>

@interface Annotation() <MKAnnotation>
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@end

@implementation Annotation
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.title, self.subtitle];
}

- (NSString *)title {
    return self.topic ? self.topic : @"";
}

- (NSString *)subtitle {
    return  [NSString stringWithFormat:@"%@ %@",
             [NSDateFormatter localizedStringFromDate:self.timeStamp
                                            dateStyle:NSDateFormatterShortStyle
                                            timeStyle:NSDateFormatterMediumStyle],
             (self.placemark) ?
             ABCreateStringWithAddressDictionary (self.placemark.addressDictionary, TRUE) :
             [NSString stringWithFormat:@"%f,%f",
              self.coordinate.latitude,
              self.coordinate.longitude] ];
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
}

- (void)getReverseGeoCode
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:self.coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:0 speed:0 timestamp:0];
    [geocoder reverseGeocodeLocation:location completionHandler:
     ^(NSArray *placemarks, NSError *error) {
         if ([placemarks count] > 0) {
             self.placemark = placemarks[0];
             [self.delegate changed:self];
         } else {
             self.placemark = nil;
         }
     }];
}

@end
