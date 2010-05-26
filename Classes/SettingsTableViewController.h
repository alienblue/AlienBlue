//
//  SettingsViewController.h
//  Alien Blue
//
//  Created by Jason Morrissey on 4/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditAPI.h"

@interface SettingsTableViewController : UITableViewController <UITextFieldDelegate> {
	UITextField *usernameField;
	UITextField *passwordField;
	UITextField *newFilterField;
	IBOutlet UILabel *modLabel;
	IBOutlet UILabel *cookieLabel;	
	NSUserDefaults * prefs;
	UIActivityIndicatorView * purchaseActivity;
	UIScrollView * proSplashView;
	UIScrollView * tipsView;
	UIView * settingsView;	
	RedditAPI * redAPI;
}

@property (nonatomic, retain) IBOutlet  UILabel *modLabel;	
@property (nonatomic, retain) IBOutlet  UILabel *cookieLabel;	

- (IBAction)authorise:(id)sender;
- (void) showTipsSplash;
- (void) stopPurchaseActivityIndicator;
- (void) showProSplash;
@end
