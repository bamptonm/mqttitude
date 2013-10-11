//
//  mqttitudeFriendTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 29.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeFriendTVC.h"
#import "Friend+Create.h"
#import "Location+Create.h"
#import "mqttitudeCoreData.h"

@interface mqttitudeFriendTVC ()

@end

@implementation mqttitudeFriendTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Friend"];
    
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"topic" ascending:YES]];
    
    if ([mqttitudeCoreData theManagedObjectContext]) {
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:[mqttitudeCoreData theManagedObjectContext]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friend"];
    
    Friend *friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = friend.name ? friend.name : friend.topic;
    
    Location *newestLocation = [self newestLocation:friend];
    [newestLocation getReverseGeoCode];
    
    cell.detailTextLabel.text = newestLocation ? (newestLocation.placemark ? newestLocation.placemark :
                                                  [NSString stringWithFormat:@"%f,%f", newestLocation.coordinate.latitude, newestLocation.coordinate.longitude]) : @"???";
    
    cell.imageView.image = friend.image ? [UIImage imageWithData:friend.image] : [UIImage imageNamed:@"icon_57x57"];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    
    if (indexPath) {
        if ([segue.identifier isEqualToString:@"setFriend:"]) {
            Friend *friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
            if ([segue.destinationViewController respondsToSelector:@selector(setFriend:)]) {
                [segue.destinationViewController performSelector:@selector(setFriend:) withObject:friend];
            }
        }
        if ([segue.identifier isEqualToString:@"setCenter:"]) {
            Friend *friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
            self.selectedLocation = [self newestLocation:friend];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Friend *friend = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.fetchedResultsController.managedObjectContext deleteObject:friend];
    }
}

#pragma newestLocation

- (Location *)newestLocation:(Friend *)friend
{
    Location *newestLocation;
    
    for (Location *location in friend.hasLocations) {
        if (!newestLocation) {
            newestLocation = location;
        } else {
            if ([newestLocation.timestamp compare:location.timestamp] == NSOrderedAscending) {
                newestLocation = location;
            }
        }
    }
    return newestLocation;
}

@end
