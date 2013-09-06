//
//  MQTTitudeSettingsTVC.m
//  MQTTitude
//
//  Created by Christoph Krey on 15.07.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "mqttitudeSettingsTVC.h"
#import "mqttitudeQoSTVC.h"
#import "mqttitudeSubscriptionsTVC.h"
#import "mqttitudePublicationsTVC.h"
#import "mqttitudeViewController.h"
#import "mqttitudeAppDelegate.h"
#import "mqttitudeLogTVC.h"
#import "mqttitudeWhereTVC.h"
#import "Connection.h"
#import "Logs.h"
#import "Annotations.h"

@interface mqttitudeSettingsTVC () <UISplitViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *UIsubscriptions;
@property (weak, nonatomic) IBOutlet UITextField *UIpublishs;

@end

@implementation mqttitudeSettingsTVC
- (void)viewWillAppear:(BOOL)animated
{
    self.UIsubscriptions.text = [NSString stringWithFormat:@"%d", [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"subs_preference"] count]];
    self.UIpublishs.text = [NSString stringWithFormat:@"%d", [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pubs_preference"] count]];
}
- (IBAction)sendNow1:(UIButton *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate sendNow];
}
- (IBAction)sendNow:(UIButton *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate sendNow];
}
- (IBAction)switchOff1:(UIButton *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate switchOff];
}
- (IBAction)switchOff:(UIButton *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate switchOff];
}

- (IBAction)save:(UIBarButtonItem *)sender {
    mqttitudeAppDelegate *delegate = (mqttitudeAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate reconnect];
}

#pragma UISplitViewControllerDelegate

- (void)awakeFromNib
{
    if (self.splitViewController) {
        self.splitViewController.delegate = self;
    }
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return YES; //UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    id detailViewController = [self.splitViewController.viewControllers lastObject];
    if ([detailViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) {
        [detailViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:nil];
    }
    if ([detailViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)detailViewController;
        
        for (id siblingsViewController in tabBarController.viewControllers) {
            if ([siblingsViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) {
                [siblingsViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:nil];
            }
        }
    }
}

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"Select";
    id detailViewController = [self.splitViewController.viewControllers lastObject];
    if ([detailViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) {
        [detailViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:barButtonItem];
    }
    if ([detailViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)detailViewController;
        
        for (id siblingsViewController in tabBarController.viewControllers) {
            if ([siblingsViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) {
                [siblingsViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:barButtonItem];
            }
        }
    }
}

- (id)splitViewDetailWithBarButtonItem
{
    id detail = [self.splitViewController.viewControllers lastObject];
    if (![detail respondsToSelector:@selector(setSplitViewBarButtonItem:)] ||
        ![detail respondsToSelector:@selector(splitViewBarButtonItem)]) detail = nil;
    return detail;
}

- (void)transferSplitViewBarButtonItemToViewController:(id)destinationViewController
{
    UIBarButtonItem *splitViewBarButtonItem = [[self splitViewDetailWithBarButtonItem] performSelector:@selector(splitViewBarButtonItem)];
    [[self splitViewDetailWithBarButtonItem] setSplitViewBarButtonItem:nil];
    if (splitViewBarButtonItem) [destinationViewController setSplitViewBarButtonItem:splitViewBarButtonItem];
}




@end
