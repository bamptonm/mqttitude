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
@property (strong, nonatomic) UIPopoverController *myPopoverController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *locationButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveButton;
@property (weak, nonatomic) Annotations *annotations;
@property (nonatomic) ABAddressBookRef ab;
@end

@implementation mqttitudeViewController

#define KEEPALIVE 600.0

- (void)viewDidLoad
{
    /*
     * Initializing all Objects
     */
    CFErrorRef error;
    
    [super viewDidLoad];

    self.mapView.delegate = self;
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    self.locationButton.style = UIBarButtonItemStyleDone;
    self.connectionButton.style = UIBarButtonItemStyleDone;
    self.moveButton.style = UIBarButtonItemStyleBordered;
    
    self.ab = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(self.ab, ^(bool granted, CFErrorRef error) {
        //
    });

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.mapView addAnnotations:self.annotations.annotationArray];
    [self showState:delegate.connection.state];
}

- (IBAction)action:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate sendNow];
}
- (IBAction)stop:(UIBarButtonItem *)sender {
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
        case state_exit:
        case state_starting:
        case state_connecting:
        case state_closing:
        default:
            [delegate reconnect];
            break;
    }
}

- (IBAction)showAll:(UIBarButtonItem *)sender {
    MKMapRect rect;
    CLLocationCoordinate2D coordinate = [self.annotations myLastAnnotation].coordinate;
    double p = 1200 * MKMapPointsPerMeterAtLatitude(coordinate.latitude);
    
    rect.origin = MKMapPointForCoordinate(coordinate);
    rect.origin.x -= p/2;
    rect.origin.y -= p/2;
    rect.size.width = p;
    rect.size.height = p;
    
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
}
- (IBAction)showCenter:(UIBarButtonItem *)sender {
    if (self.mapView.showsUserLocation) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        MKMapRect rect;
        CLLocationCoordinate2D coordinate = [self.annotations myLastAnnotation].coordinate;
        double p = 1200 * MKMapPointsPerMeterAtLatitude(coordinate.latitude);

        rect.origin = MKMapPointForCoordinate(coordinate);
        rect.origin.x -= p/2;
        rect.origin.y -= p/2;
        rect.size.width = p;
        rect.size.height = p;
        [self.mapView setVisibleMapRect:rect animated:YES];
    }
}

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController respondsToSelector:@selector(setConnection:)]) {
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
        [segue.destinationViewController performSelector:@selector(setConnection:) withObject:delegate.connection];
    }
}

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
        case state_exit:
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
        case state_exit:
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
                    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:REUSE_ID_PICTURE];
                    if (annotationView) {
                        if ([annotationView respondsToSelector:@selector(setPersonImage:)]) {
                            [annotationView performSelector:@selector(setPersonImage:) withObject:image];
                        }
                        [annotationView setNeedsDisplay];
                        return annotationView;
                    } else {
                        mqttitudeFriendAnnotationView *annotationView = [[mqttitudeFriendAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:REUSE_ID_PICTURE];
                        annotationView.personImage = image;
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

#define IMAGE_SIZE 40.0
#define SERVICE_NAME CFSTR("MQTTitude")

- (UIImage *)imageOfPerson:(NSString *)topic
{
    UIImage *image;
        
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(self.ab);
    
    for (CFIndex i = 0; i < CFArrayGetCount(records); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        
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
        CFRelease(record);
    }
    //CFRelease(records);
    return image;
}
@end
