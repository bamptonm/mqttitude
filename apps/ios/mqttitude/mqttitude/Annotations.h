//
//  Annotations.h
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Annotation.h"

@class Annotations;

@protocol AnnotationsDelegate <NSObject>
- (void)annotationsChanged:(Annotations *)annotations;
@end

@interface Annotations : NSObject <AnnotationDelegate>
@property (strong, nonatomic) NSString *myTopic;
@property (strong, nonatomic) NSMutableArray *annotationArray;
@property (strong, nonatomic) id<AnnotationsDelegate> delegate;
- (void)addLocation:(CLLocation *)location topic:(NSString *)topic;
- (NSArray *)othersAnnotations;
- (NSInteger)countOthersAnnotations;
- (Annotation *)myLastAnnotation;

@end
