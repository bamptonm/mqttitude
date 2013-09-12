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

@interface mqttitudeViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet mqttitudeIndicatorButton *indicatorButton;
@property (strong, nonatomic) UIPopoverController *myPopoverController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *locationButton;
@property (weak, nonatomic) Annotations *annotations;
@property (strong, nonatomic) MKCircle *circle;
@property (strong, nonatomic) MKCircleView *circleView;

@end

@implementation mqttitudeViewController

#define KEEPALIVE 600.0

- (void)viewDidLoad
{
    /*
     * Initializing all Objects
     */
     
    [super viewDidLoad];

    self.mapView.delegate = self;
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    self.locationButton.style = UIBarButtonItemStyleDone;
    self.connectionButton.style = UIBarButtonItemStyleDone;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.mapView addAnnotations:self.annotations.annotationArray];
    [self showState:delegate.connection.state];

    self.circle = [MKCircle circleWithCenterCoordinate:[self.annotations myLastAnnotation].coordinate
                                                radius:500.0];
    self.circleView = [[MKCircleView alloc] initWithCircle:self.circle];
    self.circleView.strokeColor = [UIColor blackColor];
    [self.mapView addOverlay:self];
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
    } else {
        self.mapView.showsUserLocation = YES;
        [delegate locationOn];
        self.locationButton.style = UIBarButtonItemStyleDone;
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
    self.circle = [MKCircle circleWithCenterCoordinate:[self.annotations myLastAnnotation].coordinate
                                                radius:500.0];
    self.circleView = [[MKCircleView alloc] initWithCircle:self.circle];
    self.circleView.strokeColor = [UIColor blackColor];
    [self.mapView removeOverlay:self];
    [self.mapView addOverlay:self];
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

#pragma MKOverlay

- (CLLocationCoordinate2D)coordinate
{
    return self.circle.coordinate;
}

- (MKMapRect)boundingMapRect
{
    return self.circle.boundingMapRect;
}

#pragma MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if (overlay == self) {
        return self.circleView;
    }
    return nil;
}

#define REUSE_ID_SELF @"MQTTitude_Annotation_self"
#define REUSE_ID_OTHER @"MQTTitude_Annotation_other"

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
        return nil;
    }
}

@end
