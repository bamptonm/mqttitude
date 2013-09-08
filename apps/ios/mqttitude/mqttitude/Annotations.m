//
//  Annotations.m
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "Annotations.h"
#import "Annotation.h"

@interface Annotations ()


@end

@implementation Annotations

- (NSMutableArray *)delegates
{
    if (!_delegates) {
        _delegates = [[NSMutableArray alloc] init];
    }
    return _delegates;
}
- (NSMutableArray *)annotationArray
{
    if (!_annotationArray) {
        _annotationArray = [[NSMutableArray alloc] init];
    }
    return _annotationArray;
}

- (NSInteger)countOthersAnnotations
{
    NSInteger i = 0;
    for (Annotation *annotation in self.annotationArray) {
        if (![annotation.topic isEqualToString:self.myTopic]) {
            i++;
        }
    }
    return i;
}

- (NSArray *)othersAnnotations
{
    NSMutableArray *othersArray = [[NSMutableArray alloc] init];
    for (Annotation *annotation in self.annotationArray) {
        if (![annotation.topic isEqualToString:self.myTopic]) {
            [othersArray addObject:annotation];
        }
    }
    return othersArray;
}

- (Annotation *)myLastAnnotation
{
    Annotation *lastAnnotation;
    
    for (Annotation *annotation in self.annotationArray) {
        if ([annotation.topic isEqualToString:self.myTopic]) {
            if (lastAnnotation) {
                if ([lastAnnotation.timeStamp compare:annotation.timeStamp] == NSOrderedAscending) {
                    lastAnnotation = annotation;
                }
            } else {
                lastAnnotation = annotation;
            }
        }
    }
    return lastAnnotation;
}

#define MAX_ANNOTATIONS 50

- (void)addLocation:(CLLocation *)location topic:(NSString *)topic
{
    // prepare annotation
    Annotation *annotation = [[Annotation alloc] init];
    annotation.delegate = self;
    annotation.coordinate = location.coordinate;
    annotation.timeStamp = location.timestamp;
    annotation.topic = topic;
    
    // if other's location, delete previous
    if (![annotation.topic isEqualToString:self.myTopic]) {
        for (Annotation *theAnnotation in self.annotationArray) {
            if ([theAnnotation.topic isEqualToString:annotation.topic]) {
                [self.annotationArray removeObject:theAnnotation];
                break;
            }
        }
    }
    
    // add the new annotation to the map, for reference
    [self.annotationArray addObject:annotation];
    
    // limit the total number of annotations
    if ([self.annotationArray count] > MAX_ANNOTATIONS) {
        [self.annotationArray removeObjectAtIndex:0];
    }
    
    // count other's annotation
    NSInteger others = 0;
    for (Annotation *theAnnotation in self.annotationArray) {
        if (![theAnnotation.topic isEqualToString:self.myTopic]) {
            others++;
        }
    }
    
    // show the user how many others are on the map
    [UIApplication sharedApplication].applicationIconBadgeNumber = others;

    for (id<AnnotationsDelegate> delegate in self.delegates) {
        [delegate changed:self.annotationArray];
    }
}

#pragma AnnotationDelegate

- (void)changed:(Annotation *)annotation
{
    for (id<AnnotationsDelegate> delegate in self.delegates) {
        [delegate changed:self.annotationArray];
    }
}

@end
