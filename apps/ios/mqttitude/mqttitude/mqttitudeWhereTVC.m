//
//  mqttitudeWhereTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeWhereTVC.h"
#import "mqttitudeAppDelegate.h"
#import "Annotation.h"

@interface mqttitudeWhereTVC ()

@end

@implementation mqttitudeWhereTVC

- (void)setAnnotations:(Annotations *)annotations
{
    _annotations = annotations;
    [_annotations.delegates addObject:self];
}

#pragma mark - AnnotationsDelegate

- (void)changed:(Annotations *)annotations
{
   [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section) {
        return [self.annotations countOthersAnnotations];
    } else {
        return 1;
    }
}
- (IBAction)action:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate sendNow];

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section) {
        return NSLocalizedString(@"Friends & Family", @"Section Header for other shown locations");
    } else {
        return NSLocalizedString(@"Me, myself, and I", @"Section Header for my shown location");
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"where";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Annotation *annotation;
    
    if (indexPath.section) {
        NSArray *array = [self.annotations othersAnnotations];
        annotation = array[indexPath.row];
    } else {
        annotation = [self.annotations myLastAnnotation];
    }
    [annotation getReverseGeoCode];
    cell.textLabel.text = [annotation title];
    cell.detailTextLabel.text = [annotation subtitle];
    
    return cell;
}

@end
