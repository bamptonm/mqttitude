//
//  mqttitudeSubscriptionsTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 31.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeSubscriptionsTVC.h"
#import "mqttitudeQoSTVC.h"
#import "mqttitudeSubscriptionTVC.h"
#import "mqttitudeAppDelegate.h"

@interface mqttitudeSubscriptionsTVC ()

@end

@implementation mqttitudeSubscriptionsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[mqttitudeSubscriptionTVC class]]) {
        mqttitudeSubscriptionTVC *sub = (mqttitudeSubscriptionTVC *)segue.destinationViewController;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            NSDictionary *subs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"];
            if (indexPath.row < [subs count]) {
                NSArray *array = [[subs allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                
                sub.oldTopic = array[indexPath.row];
                sub.topic = array[indexPath.row];
                sub.qos = [subs[array[indexPath.row]] integerValue];
            } else {
                sub.oldTopic = nil;
                sub.topic = @"";
                sub.qos = 0;
            }
        }
    }
}


- (IBAction)settingsSaved:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[mqttitudeSubscriptionTVC class]]) {
        mqttitudeSubscriptionTVC *sub = (mqttitudeSubscriptionTVC *)segue.sourceViewController;
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
        
        NSMutableDictionary *subs = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"] mutableCopy];
        if (sub.oldTopic) {
            [subs removeObjectForKey:sub.oldTopic];
            [delegate.connection unsubscribe:sub.oldTopic];
        }

        subs[sub.topic] = @(sub.qos);
        [[NSUserDefaults standardUserDefaults] setObject:subs forKey:@"subs_preference"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [delegate.connection subscribe:sub.topic qos:sub.qos];
        
        [self.tableView reloadData];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"] count] + 1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"] count]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"subscription";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *subs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"];
    if (indexPath.row < [subs count]) {
        NSArray *array = [[subs allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        cell.textLabel.text = array[indexPath.row];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",
                                     [subs[array[indexPath.row]] integerValue]];
    } else {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableDictionary *subs = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"] mutableCopy];
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;

        NSArray *array = [[subs allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        [delegate.connection unsubscribe:array[indexPath.row]];
        [subs removeObjectForKey:array[indexPath.row]];
        [[NSUserDefaults standardUserDefaults] setObject:subs forKey:@"subs_preference"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self performSegueWithIdentifier:@"subscription" sender:nil];
    }
}

@end
