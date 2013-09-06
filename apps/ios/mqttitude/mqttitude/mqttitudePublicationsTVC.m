//
//  mqttitudePublicationsTVC.m
//  mqttitude
//
//  Created by Christoph Krey on 01.09.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudePublicationsTVC.h"
#import "mqttitudePublicationTVC.h"
#import "mqttitudeAppDelegate.h"

@interface mqttitudePublicationsTVC ()

@end

@implementation mqttitudePublicationsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[mqttitudePublicationTVC class]]) {
        mqttitudePublicationTVC *pub = (mqttitudePublicationTVC *)segue.destinationViewController;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            NSDictionary *pubs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"];

            if (indexPath.row < [pubs count]) {
                NSArray *array = [[pubs allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                
                pub.oldTopic = array[indexPath.row];
                pub.topic = array[indexPath.row];
                NSDictionary *dictionary = pubs[array[indexPath.row]];
                pub.qos = [dictionary[@"QOS"] integerValue];
                pub.retainFlag = [dictionary[@"RETAINFLAG"] boolValue];
                pub.data = dictionary[@"DATA"];
            } else {
                pub.oldTopic = nil;
                pub.topic = @"";
                pub.qos = 0;
                pub.retainFlag = FALSE;
                pub.data = [[NSData alloc] init];
            }
        }
    }
}

- (IBAction)settingsSaved:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[mqttitudePublicationTVC class]]) {
        mqttitudePublicationTVC *pub = (mqttitudePublicationTVC *)segue.sourceViewController;
        NSMutableDictionary *pubs = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"] mutableCopy];
        mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;

        if (pub.oldTopic) {
            [pubs removeObjectForKey:pub.oldTopic];
        }
        
        pubs[pub.topic] = @{
                            @"QOS": @(pub.qos),
                            @"RETAINFLAG": @(pub.retainFlag),
                            @"DATA": pub.data
                            };
        [[NSUserDefaults standardUserDefaults] setObject:pubs forKey:@"pubs_preference"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [delegate.connection sendData:pub.data topic:pub.topic qos:pub.qos retain:pub.retainFlag];
        
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
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"] count] + 1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"] count]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleInsert;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"publish";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *pubs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"];
                          
    if (indexPath.row < [pubs count]) {
        NSArray *array = [[pubs allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        cell.textLabel.text = array[indexPath.row];
        NSDictionary *dictionary = pubs[array[indexPath.row]];
        cell.detailTextLabel.text = [Connection dataToString:dictionary[@"DATA"]];
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
        NSMutableDictionary *pubs = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"] mutableCopy];

        NSArray *array = [[pubs allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        [pubs removeObjectForKey:array[indexPath.row]];
        [[NSUserDefaults standardUserDefaults] setObject:pubs forKey:@"pubs_preference"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self performSegueWithIdentifier:@"publication" sender:nil];
    }
}


@end
