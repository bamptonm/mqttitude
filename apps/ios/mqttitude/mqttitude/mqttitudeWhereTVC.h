//
//  mqttitudeWhereTVC.h
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Annotations.h"

@interface mqttitudeWhereTVC : UITableViewController <AnnotationsDelegate>
@property (weak, nonatomic) Annotations *annotations;

@end
