//
//  mqttitudeViewController.m
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeViewController.h"
#import "mqttitudeSettingsTVC.h"
#import "mqttitudeLogTVC.h"
#import "mqttitudeAppDelegate.h"
#import "Annotation.h"
#import "Logs.h"
#import "mqttitudeIndicatorView.h"

@interface mqttitudeViewController ()
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet mqttitudeIndicatorView *indicatorView;

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.mapView addAnnotations:self.annotations.annotationArray];
    [self showState:delegate.connection.state];
}

- (void)setAnnotations:(Annotations *)annotations
{
    _annotations = annotations;
    [_annotations.delegates addObject:self];
}
- (IBAction)action:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate sendNow];
}

- (IBAction)showAll:(UIBarButtonItem *)sender {
    MKMapRect rect;
    rect.origin = MKMapPointForCoordinate([self.annotations myLastAnnotation].coordinate);
    rect.size.width = 100;
    rect.size.height = 100;
    
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
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)changed:(NSArray *)annotations
{
    [self.mapView addAnnotations:annotations];
}

- (void)showState:(NSInteger)state
{
    UIColor *color;
    
    switch (state) {
        case state_connected:
            color = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5];
            break;
        case state_error:
            color = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
            break;
        case state_connecting:
        case state_closing:
            color = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.5];
            break;
        case state_starting:
        case state_exit:
        default:
            color = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5];
            break;
    }
        
    self.indicatorView.color  = color;
    [self.indicatorView setNeedsDisplay];

}

#pragma MKMapViewDelegate

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


#pragma SplitViewBarButtonItem

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    UIToolbar *toolbar = [self toolbar];
    NSMutableArray *toolbarItems = [toolbar.items mutableCopy];
    if (_splitViewBarButtonItem) [toolbarItems removeObject:self.splitViewBarButtonItem];
    if (barButtonItem) [toolbarItems insertObject:barButtonItem atIndex:0];
    toolbar.items = toolbarItems;
    _splitViewBarButtonItem = barButtonItem;
    
}


@end
