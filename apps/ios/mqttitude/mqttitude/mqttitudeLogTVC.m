//
//  mqttitudeLogTVCViewController.m
//  mqttitude
//
//  Created by Christoph Krey on 17.08.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeLogTVC.h"
#import "mqttitudeAppDelegate.h"

@interface mqttitudeLogTVC ()

@end

@implementation mqttitudeLogTVC

- (void)setLogs:(Logs *)logs
{
    _logs = logs;
    _logs.delegate = self;
}

- (void)insert:(Logs *)logs at:(NSInteger)pos
{
    NSArray *array = @[
                       [NSIndexPath indexPathForRow:pos inSection:0]
                       ];
    [self.tableView insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (IBAction)action:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate sendNow];
}

- (void)changed:(Logs *)logs
{
    //[self.tableView reloadData];
}

- (void)remove:(Logs *)logs at:(NSInteger)pos
{
    NSArray *array = @[
                       [NSIndexPath indexPathForRow:pos inSection:0]
                       ];
    [self.tableView deleteRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.logs count];
}

#define REUSE_IDENTIFIER @"log"
#define TEXTVIEW_TAG 1

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell= [tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER
                                                           forIndexPath:indexPath];
    
    UITextView *textView = (UITextView *)[cell.contentView viewWithTag:TEXTVIEW_TAG];    
    textView.text = [self.logs elementAtPosition:indexPath.row];
    
    return cell;
    
}



@end
