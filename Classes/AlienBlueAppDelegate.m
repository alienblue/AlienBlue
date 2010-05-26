//
//  AlienBlueAppDelegate.m
//  Alien Blue
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright The Design Shed 2010. All rights reserved.
//

#import "AlienBlueAppDelegate.h"
#import "MessagesTableViewController.h"
#import "SettingsTableViewController.h"

@implementation AlienBlueAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize redditAPI;
@synthesize blackBG;

- (void) authtest1:(id) sender
{
	NSLog(@"authtest1 in()");
	if ([redditAPI authenticated])
	{
		NSLog(@"-- user is authenticated --");
		[self refreshUnreadMailBadge];
	}
	else
		NSLog(@"-- not logged in --");
}

-(IBAction) checkForNewMessages: (id) sender
{
	if ([redditAPI authenticated])
		[redditAPI fetchUnreadMessageCount:self];
}

-(IBAction) apiUnreadMessageCountResponse: (id) sender
{
	NSLog(@"-- new results for unread message count : %d", [redditAPI unreadMessageCount]);
	[self refreshUnreadMailBadge];
}

- (void) refreshUnreadMailBadge
{
	UITabBarItem *  messagesTab = [[[tabBarController tabBar] items] objectAtIndex:1];
	if([redditAPI unreadMessageCount] > 0)
	{
		[messagesTab setBadgeValue:[NSString stringWithFormat:@"%d",[redditAPI unreadMessageCount]]];
	}
	else
	{
		[messagesTab setBadgeValue:nil];
	}
}


// this is to handle users clicking "Upgrade Now" in UIAlert dialogs
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView.tag == 99 && buttonIndex == 1)
	{
		NSLog(@"Upgrade Now Pressed");
		[tabBarController setSelectedIndex:2];

		NSIndexPath * ind = [NSIndexPath indexPathForRow:0 inSection:7];
		[[(SettingsTableViewController *) [tabBarController selectedViewController] tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionTop animated:NO];
	}
}

- (void) refreshBackground
{
	if ([prefs boolForKey:@"night_mode"])
		[blackBG setHidden:NO];
	else
		[blackBG setHidden:YES];		
}

- (void) stopPurchaseIndicator
{
	if ([tabBarController selectedIndex] == 2)
	{
		[(SettingsTableViewController *) [tabBarController selectedViewController] stopPurchaseActivityIndicator];
	}
}

- (void) proVersionUpgraded
{
	NSLog(@"proVersionUpgraded");

	if ([tabBarController selectedIndex] == 2)
	{
		// refresh settings - so that the "Thank you message" now displays
		[[(SettingsTableViewController *) [tabBarController selectedViewController] tableView] reloadData];
		[(SettingsTableViewController *) [tabBarController selectedViewController] stopPurchaseActivityIndicator];
	}
}

- (void) showConnectionErrorImage
{
	if (![errorImage superview])
		[window insertSubview:errorImage atIndex:99];
}

- (void) hideConnectionErrorImage
{
	if ([errorImage superview])
		[errorImage removeFromSuperview];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {

	errorImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"no-internet-connection.png"] retain]];
		
	prefs = [NSUserDefaults standardUserDefaults];	
	
	// setup the default user settings on first launch
	if(![prefs boolForKey:@"already_ran"] ) 
	{
		[prefs setBool:YES forKey:@"already_ran"];

		[prefs setBool:YES forKey:@"use_lowres_imgur"];
		[prefs setBool:YES forKey:@"use_direct_imgur_link"];

		[prefs setBool:YES forKey:@"show_hide_queue"];
		[prefs setBool:YES forKey:@"show_thumbs"];
		[prefs setBool:YES forKey:@"show_help_icon"];
		[prefs setBool:NO forKey:@"night_mode"];
		[prefs setBool:NO forKey:@"auto_mark_as_read"];
		[prefs setBool:YES forKey:@"allow_rotation"];
		[prefs setBool:YES forKey:@"allow_status_bar_scroll"];
		[prefs setBool:NO forKey:@"show_quick_scroll"];
		[prefs setBool:NO forKey:@"allow_tilt_scroll"];
		[prefs setInteger:1 forKey:@"textsize"];
		[prefs setInteger:0 forKey:@"fetch_message_frequency"];
		[prefs synchronize];
	}

	if(![prefs objectForKey:@"filterList"])
	{
		NSLog(@"initialising post filter");
		NSMutableArray * filterList = [NSMutableArray arrayWithCapacity:1];
		[prefs setObject:filterList forKey:@"filterList"];
		[prefs synchronize];
	}
	else
	{
		NSMutableArray * filterList = (NSMutableArray *) [prefs objectForKey:@"filterList"];
		for (NSString * filterItem in filterList)
		{
			NSLog(@"Filter Item : %@", filterItem);
		}
	}
	
	
	// Always disable tilt-scroll on launch.  Otherwise, the user is going to get
	// unexpected scrolling if they forgot that tilt-scroll was activated previously.
   	[prefs setBool:NO forKey:@"allow_tilt_scroll"];
	[prefs synchronize];
	
	[MKStoreManager sharedManager];

	if([MKStoreManager isProUpgraded])
	{
		NSLog(@"-- pro version in use --");
	}	
	else
	{
		NSLog(@"-- free version in use --");
	}
	
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];
	[tabBarController setDelegate:tabBarController];

	redditAPI = [[RedditAPI alloc] init];
	[tabBarController loadNibs];

	[redditAPI testReachability];
	
	[redditAPI authenticateWithCallbackTarget:self andCallBackAction:@"authtest1:"];
	int freq_selection = [[prefs valueForKey:@"fetch_message_frequency"] intValue];
	int checkTime = -1;
	if (freq_selection == 1)
		checkTime = 2 * 60;
	else if (freq_selection == 2)
		checkTime = 5 * 60;
	else if (freq_selection == 3)
		checkTime = 10 * 60;
			

	if (checkTime > 0)
	{
		NSLog(@"-- will check for messages every %d minutes", checkTime / 60);
		inboxCheckTimer = [NSTimer scheduledTimerWithTimeInterval:checkTime
														   target:self
														 selector:@selector(checkForNewMessages:)
														 userInfo:nil
														  repeats:YES];	
	}	
	else 
		NSLog(@"-- manual message checking --");
	
	[self refreshBackground];
	
//	[self showConnectionErrorImage];
}


/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}



@end

