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
@property (strong, nonatomic) NSMutableArray *array;
@end

@implementation Annotations

- (NSMutableArray *)array
{
    if (!_array) {
        _array = [[NSMutableArray alloc] init];
    }
    return _array;
}

- (NSArray *)annotationArray
{
    return self.array;
}


- (NSInteger)countOthersAnnotations
{
    NSInteger i = 0;
    for (Annotation *annotation in self.array) {
        if (![annotation.topic isEqualToString:self.myTopic]) {
            i++;
        }
    }
    return i;
}

- (NSArray *)othersAnnotations
{
    NSMutableArray *othersArray = [[NSMutableArray alloc] init];
    for (Annotation *annotation in self.array) {
        if (![annotation.topic isEqualToString:self.myTopic]) {
            [othersArray addObject:annotation];
        }
    }
    return othersArray;
}

- (Annotation *)myLastAnnotation
{
    Annotation *lastAnnotation;
    
    for (Annotation *annotation in self.array) {
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


- (Annotation *)myOldestAnnotation
{
    Annotation *oldestAnnotation;
    
    for (Annotation *annotation in self.array) {
        if ([annotation.topic isEqualToString:self.myTopic]) {
            if (oldestAnnotation) {
                if ([oldestAnnotation.timeStamp compare:annotation.timeStamp] == NSOrderedDescending) {
                    oldestAnnotation = annotation;
                }
            } else {
                oldestAnnotation = annotation;
            }
        }
    }
    return oldestAnnotation;
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
        for (Annotation *theAnnotation in self.array) {
            if ([theAnnotation.topic isEqualToString:annotation.topic]) {
                [self.array removeObject:theAnnotation];
                break;
            }
        }
    }
    
    // add the new annotation to the map, for reference
    [self.array addObject:annotation];
    
    // count own and other's annotation
    NSInteger own = 0;
    for (Annotation *theAnnotation in self.array) {
        if ([theAnnotation.topic isEqualToString:self.myTopic]) {
            own++;
        }
    }
    
    // limit the total number of own annotations
    if (own > MAX_ANNOTATIONS) {
        [self.array removeObject:[self myOldestAnnotation]];
    }
        
    [self.delegate annotationsChanged:self];
}

#pragma AnnotationDelegate

- (void)changed:(Annotation *)annotation
{
    [self.delegate annotationsChanged:self];
}

@end
