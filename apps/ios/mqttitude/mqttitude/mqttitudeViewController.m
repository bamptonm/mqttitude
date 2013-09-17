//
//  mqttitudeViewController.m
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeViewController.h"
#import "mqttitudeAppDelegate.h"
#import "Annotation.h"
#import "mqttitudeIndicatorButton.h"
#import "mqttitudeStatusTVC.h"
#import <AddressBook/AddressBook.h>
#import "mqttitudeFriendAnnotationView.h"

@interface mqttitudeViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet mqttitudeIndicatorButton *indicatorButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *locationButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *centerButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *allButton;

@property (weak, nonatomic) Annotations *annotations;
@property (nonatomic) ABAddressBookRef ab;
@property (nonatomic) BOOL centered;
@end

@implementation mqttitudeViewController

#define KEEPALIVE 600.0

- (void)viewDidLoad
{
    CFErrorRef error;
    
    [super viewDidLoad];
    
    self.centered = TRUE;
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    self.ab = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(self.ab, ^(bool granted, CFErrorRef error) {
        // assuming access is granted
    });

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.mapView addAnnotations:self.annotations.annotationArray];
    
    [self showState:delegate.connection.state];
    
    if (self.centered) {
        [self showCenter:Nil];
        
    } else {
        [self showAll:Nil];
    }
    
    if (self.mapView.showsUserLocation) {
        self.locationButton.style = UIBarButtonItemStyleDone;
    } else {
        self.locationButton.style = UIBarButtonItemStyleBordered;
    }
    
    if (delegate.high) {
        self.moveButton.style = UIBarButtonItemStyleDone;
    } else {
        self.moveButton.style = UIBarButtonItemStyleBordered;
    }
}

#pragma UI actions

- (IBAction)location:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if (self.mapView.showsUserLocation) {
        self.mapView.showsUserLocation = NO;
        [delegate locationOff];
        self.locationButton.style = UIBarButtonItemStyleBordered;
        [delegate locationLow];
        self.moveButton.style = UIBarButtonItemStyleBordered;
    } else {
        self.mapView.showsUserLocation = YES;
        [delegate locationOn];
        self.locationButton.style = UIBarButtonItemStyleDone;
    }
}

- (IBAction)action:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate sendNow];
}

- (IBAction)move:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if (delegate.high) {
        [delegate locationLow];
        self.moveButton.style = UIBarButtonItemStyleBordered;
    } else {
        self.mapView.showsUserLocation = YES;
        [delegate locationOn];
        self.locationButton.style = UIBarButtonItemStyleDone;
        [delegate locationHigh];
        self.moveButton.style = UIBarButtonItemStyleDone;
    }
}

- (IBAction)connection:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    switch (delegate.connection.state) {
        case state_connected:
            [delegate connectionOff];
            break;
        case state_error:
        case state_starting:
        case state_connecting:
        case state_closing:
        default:
            [delegate reconnect];
            break;
    }
}

- (IBAction)showAll:(UIBarButtonItem *)sender {
    MKMapRect rect = [self initialRect];
    
    for (Annotation *annotation in self.annotations.annotationArray)
    {
        MKMapPoint point = MKMapPointForCoordinate(annotation.coordinate);
        if (point.x < rect.origin.x) {
            rect.size.width += rect.origin.x - point.x;
            rect.origin.x = point.x;
        }
        if (point.x > rect.origin.x + rect.size.width) {
            rect.size.width += point.x - rect.origin.x;
        }
        if (point.y < rect.origin.y) {
            rect.size.height += rect.origin.y - point.y;
            rect.origin.y = point.y;
        }
        if (point.y > rect.origin.y + rect.size.height) {
            rect.size.height += point.y - rect.origin.y;
        }
    }
    
    rect.origin.x -= rect.size.width/10.0;
    rect.origin.y -= rect.size.height/10.0;
    rect.size.width *= 1.2;
    rect.size.height *= 1.2;
    
    [self.mapView setVisibleMapRect:rect animated:YES];
    self.centered = FALSE;
    self.centerButton.style = UIBarButtonItemStyleBordered;
    self.allButton.style = UIBarButtonItemStyleDone;
}
- (IBAction)showCenter:(UIBarButtonItem *)sender {
    if (self.mapView.showsUserLocation) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [self.mapView setVisibleMapRect:[self initialRect] animated:YES];
    }
    self.centered = TRUE;
    self.centerButton.style = UIBarButtonItemStyleDone;
    self.allButton.style = UIBarButtonItemStyleBordered;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    /*
     * segue for connection status view
     */
    
    if ([segue.destinationViewController respondsToSelector:@selector(setConnection:)]) {
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
        [segue.destinationViewController performSelector:@selector(setConnection:) withObject:delegate.connection];
    }
}

#pragma initialRect

#define INITIAL_RADIUS 600.0

- (MKMapRect)initialRect
{
    MKMapRect rect;
    CLLocationCoordinate2D coordinate;
    
    /* start with my own last location published */
    if ([self.annotations myLastAnnotation]) {
        coordinate = [self.annotations myLastAnnotation].coordinate;
        
    } else {
        /* if this is not set yet, use location manager */
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
        coordinate = delegate.manager.location.coordinate;
    }
    
    double r = INITIAL_RADIUS * MKMapPointsPerMeterAtLatitude(coordinate.latitude);
    
    rect.origin = MKMapPointForCoordinate(coordinate);
    rect.origin.x -= r;
    rect.origin.y -= r;
    rect.size.width = 2*r;
    rect.size.height = 2*r;
    
    return rect;
}

#pragma AnnotationsDelegate

- (void)annotationsChanged:(Annotations *)annotations
{
    self.annotations = annotations;
    /**
     * remove all annnotations no longer in the annotions array from the map
     * with the exception of the current user location
     **/
    for (id a in self.mapView.annotations) {
        if (![a isKindOfClass:[MKUserLocation class]]) {
            if (![annotations.annotationArray containsObject:a]) {
                [self.mapView removeAnnotation:a];
            }
        }
    }
    
    /**
     * add all new annotations
     **/
    for (id a in annotations.annotationArray) {
        if (![self.mapView.annotations containsObject:a]) {
            [self.mapView addAnnotation:a];
        }
    }
}

#pragma ConnectionDelegate

- (void)showState:(NSInteger)state
{
    UIColor *color;
    
    switch (state) {
        case state_connected:
            color = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
            break;
        case state_error:
            color = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
            break;
        case state_connecting:
        case state_closing:
            color = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
            break;
        case state_starting:
        default:
            color = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
            break;
    }
        
    self.indicatorButton.color  = color;
    [self.indicatorButton setNeedsDisplay];
    
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    switch (delegate.connection.state) {
        case state_connected:
            self.connectionButton.style = UIBarButtonItemStyleDone;
            break;
        case state_error:
        case state_starting:
        case state_connecting:
        case state_closing:
        default:
            self.connectionButton.style = UIBarButtonItemStyleBordered;
            break;
    }
}

#pragma MKMapViewDelegate

#define REUSE_ID_SELF @"MQTTitude_Annotation_self"
#define REUSE_ID_OTHER @"MQTTitude_Annotation_other"
#define REUSE_ID_PICTURE @"MQTTitude_Annotation_picture"
#define OLD_TIME -12*60*60

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    } else {
        if ([annotation isKindOfClass:[Annotation class]]) {
            Annotation *MQTTannotation = (Annotation *)annotation;
            if ([MQTTannotation.topic isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"topic_preference"]]) {
                MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:REUSE_ID_SELF];
                if (annotationView) {
                    return annotationView;
                } else {
                    MKPinAnnotationView *pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:REUSE_ID_SELF];
                    pinAnnotationView.pinColor = MKPinAnnotationColorRed;
                    pinAnnotationView.canShowCallout = YES;
                    return pinAnnotationView;
                }
            } else {
                UIImage *image = [self imageOfPerson:MQTTannotation.topic];
                if (image) {
                    UIColor *color;
                    if ([MQTTannotation.timeStamp compare:[NSDate dateWithTimeIntervalSinceNow:OLD_TIME]] == NSOrderedAscending) {
                        color = [UIColor redColor];
                    } else {
                        color = [UIColor greenColor];
                    }

                    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:REUSE_ID_PICTURE];
                    if (annotationView) {
                        if ([annotationView respondsToSelector:@selector(setPersonImage:)]) {
                            [annotationView performSelector:@selector(setPersonImage:) withObject:image];
                        }
                        if ([annotationView respondsToSelector:@selector(setCircleColor:)]) {
                            [annotationView performSelector:@selector(setCircleColor:) withObject:color];
                        }

                        [annotationView setNeedsDisplay];
                        return annotationView;
                    } else {
                        mqttitudeFriendAnnotationView *annotationView = [[mqttitudeFriendAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:REUSE_ID_PICTURE];
                        annotationView.personImage = image;
                        annotationView.circleColor = color;
                        annotationView.canShowCallout = YES;
                        return annotationView;
                    }
                } else {
                    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:REUSE_ID_OTHER];
                    if (annotationView) {
                        return annotationView;
                    } else {
                        MKPinAnnotationView *pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:REUSE_ID_OTHER];
                        pinAnnotationView.pinColor = MKPinAnnotationColorGreen;
                        pinAnnotationView.canShowCallout = YES;
                        return pinAnnotationView;
                    }
                }
                
            }
        }
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation respondsToSelector:@selector(getReverseGeoCode)]) {
        [view.annotation performSelector:@selector(getReverseGeoCode)];
    }
}

#pragma image of person

#define IMAGE_SIZE 40.0
#define SERVICE_NAME CFSTR("MQTTitude")
#define RELATION_NAME CFSTR("MQTTitude")

- (UIImage *)imageOfPerson:(NSString *)topic
{
    UIImage *image;
        
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(self.ab);
    
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
                    if (CFStringCompare( CFDictionaryGetValue(socialValue, kABPersonSocialProfileUsernameKey), (__bridge CFStringRef)(topic), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        if (ABPersonHasImageData(record)) {
                            CFDataRef imageData = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
                            image = [UIImage imageWithData:(__bridge NSData *)(imageData)];
                        }
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
                    if(CFStringCompare(value, (__bridge CFStringRef)(topic), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
                        if (ABPersonHasImageData(record)) {
                            CFDataRef imageData = ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
                            image = [UIImage imageWithData:(__bridge NSData *)(imageData)];
                        }
                    }
                }
            }
            CFRelease(relations);
        }
        
        CFRelease(record);
    }
    //CFRelease(records);
    return image;
}
@end
