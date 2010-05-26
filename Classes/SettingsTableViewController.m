//
//  SettingsViewController.m
//  Alien Blue
//
//  Created by Jason Morrissey on 4/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AlienBlueAppDelegate.h"


static UIImage * proFeatureLabelImage;
static UIImage * upgradeNowLabel;
static UIImage * starImage;
static UIImage * deleteImage;

#define SECTION_HEADER_HEIGHT 40

#define NUM_SETTING_SECTIONS 9

#define SECTION_REDDIT_ACCOUNT 0
#define SECTION_MESSAGE_FETCH 1
#define SECTION_VIEWING_MESSAGE 2
#define SECTION_DISPLAY  3
#define SECTION_FONTS  4
#define SECTION_FILTER  5
#define SECTION_ADVANCED 6
#define SECTION_UPGRADE_PRO 7
#define SECTION_CONTACT  8
#define SECTION_HELP  9
#define SECTION_ACKNOWLEDGEMENTS 10

#define NUM_ROWS_REDDIT_ACCOUNT 3
#define NUM_ROWS_MESSAGE_FETCH 4
#define NUM_ROWS_VIEWING_MESSAGE 1
#define NUM_ROWS_DISPLAY 6
#define NUM_ROWS_UPGRADE_PRO 2
#define NUM_ROWS_ADVANCED 3
#define NUM_ROWS_CONTACT 3
#define NUM_ROWS_FONTS 3
#define NUM_ROWS_HELP  2
#define NUM_ROWS_ACKNOWLEDGEMENTS 4

@implementation SettingsTableViewController

@synthesize modLabel;
@synthesize cookieLabel;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView.tag == 1 && buttonIndex == 1)
	{
		NSLog(@"launch Mail app in()");
		NSString *url = [NSString stringWithString: @"mailto:support@alienblue.org?subject=AlienBlue%20Fault"];
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
		
	}
	if(alertView.tag == 2 && buttonIndex == 1)
	{
		NSLog(@"launch safari in()");
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://alienblue.org"]];
	}
}

- (void) saveSettings
{
//	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
//	[prefs setObject:[username text] forKey:@"username"];
//	[prefs setObject:[password text] forKey:@"password"];
//	[prefs synchronize];
}

- (void) loadSettings
{
//	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
//	[username setText:[prefs objectForKey:@"username"]];
//	[password setText:[prefs objectForKey:@"password"]];
//	[modLabel setText:[prefs objectForKey:@"modhash"]];
//	[cookieLabel setText:[prefs objectForKey:@"cookie"]];

}

	
- (IBAction)apiLoginResponse:(id)sender {
	NSLog(@"SettingsViewController :: apiLoginResponse()");
	NSString * modhash = (NSString *) sender;
	NSLog(modhash);

	if ([modhash length] > 0)
	{
		[[self tableView] reloadData];
		
		// reload the Posts in the other view (as the user likely has their own
		// preferred subscribed reddits.
		NavigationController * nc = (NavigationController *) [self parentViewController];
		[nc clearAndRefreshPosts];

//		[self saveSettings];
//		
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorised" message:@"You have successfully logged into your Reddit account.  Your subscribed reddits, saved posts and messages are now available." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//		[alert show];
//		[alert release];
	}
}


- (IBAction)authorise:(id)sender
{
	NSLog(@"-- authorise in");
	[prefs setObject:[usernameField text] forKey:@"username"];
	[prefs setObject:[passwordField text] forKey:@"password"];
	[prefs synchronize];
	redAPI = [(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];
	[redAPI loginUser:[prefs valueForKey:@"username"] withPassword:[prefs valueForKey:@"password"] callBackTarget:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (textField == newFilterField)
	{
		[textField setText:@""];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == usernameField)
	{
		[prefs setValue:[textField text] forKey:@"username"];
		[prefs synchronize];
		NSLog(@"username changed");
	}
	if (textField  == passwordField)
	{
		[prefs setValue:[textField text] forKey:@"password"];
		[prefs synchronize];
		NSLog(@"password changed");
	}
	if (textField == newFilterField)
	{
		if ([[textField text] length] < 3)
		{
			[textField setText:@"Add a filter..."];	
		}
		else
		{
			NSMutableArray * filterList = [NSMutableArray arrayWithArray:[prefs objectForKey:@"filterList"]];
			[filterList addObject:[newFilterField text]];
			[prefs setObject:filterList forKey:@"filterList"];
			[prefs synchronize];
		}
		[[self tableView] reloadData];		
	}
//	[self saveSettings];
}

- (IBAction) removeFilterItem:(id)sender 
{
	UIButton * b = (UIButton *) sender;
	int removeIndex = [b tag];
	NSMutableArray * filterList = [NSMutableArray arrayWithArray:[prefs objectForKey:@"filterList"]];
	[filterList removeObjectAtIndex:removeIndex];
	[prefs setObject:filterList forKey:@"filterList"];
	[prefs synchronize];
	NSIndexPath * ip = [NSIndexPath indexPathForRow:removeIndex inSection:SECTION_FILTER];
	NSArray * arr = [NSArray arrayWithObject:ip];
	[[self tableView] deleteRowsAtIndexPaths:arr withRowAnimation:YES];
	[[self tableView] reloadData];
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


- (void) drawTipsSplashImage
{
//	CGRect screenFrame = [UIScreen mainScreen].applicationFrame;

	tipsView = [[UIScrollView alloc] init];
	UIImageView * tipsImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tips-sheet.png"] retain]];
	[tipsView addSubview:tipsImage];
	
	UIButton * backButton1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[backButton1 setImage:[UIImage imageNamed:@"orange-back-button.png"] forState:UIControlStateNormal];
	[backButton1 setFrame:CGRectMake(15, 22, 73, 25)];
	[backButton1 addTarget:self action:@selector(hideSplash:) forControlEvents:UIControlEventTouchUpInside];

	UIButton * backButton2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[backButton2 addTarget:self action:@selector(hideSplash:) forControlEvents:UIControlEventTouchUpInside];
	[backButton2 setImage:[UIImage imageNamed:@"orange-back-button.png"] forState:UIControlStateNormal];
	[backButton2 setFrame:CGRectMake(15, 7290, 73, 25)];
	
	
	[tipsView addSubview:backButton1];
	[tipsView addSubview:backButton2];
	[tipsView setShowsVerticalScrollIndicator:YES];
}

- (void) drawProSplashImage
{
	//	CGRect screenFrame = [UIScreen mainScreen].applicationFrame;
	
	proSplashView = [[UIScrollView alloc] init];
	UIImageView * proSplashImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"why-go-pro-splash.png"] retain]];
	[proSplashView addSubview:proSplashImage];
	
	UIButton * backButton1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[backButton1 setImage:[UIImage imageNamed:@"orange-back-button.png"] forState:UIControlStateNormal];
	[backButton1 setFrame:CGRectMake(15, 22, 73, 25)];
	[backButton1 addTarget:self action:@selector(hideSplash:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton * backButton2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[backButton2 addTarget:self action:@selector(hideSplash:) forControlEvents:UIControlEventTouchUpInside];
	[backButton2 setImage:[UIImage imageNamed:@"orange-back-button.png"] forState:UIControlStateNormal];
	[backButton2 setFrame:CGRectMake(15, [proSplashImage bounds].size.height - 50, 73, 25)];
	
	
	[proSplashView addSubview:backButton1];
	[proSplashView addSubview:backButton2];
	[proSplashView setShowsVerticalScrollIndicator:FALSE];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	proFeatureLabelImage = [[UIImage imageNamed:@"pro-feature-label.png"] retain];
	upgradeNowLabel = [[UIImage imageNamed:@"upgrade-to-pro-label.png"] retain];
	starImage = [[UIImage imageNamed:@"star-selected-icon.png"] retain];
	deleteImage = [[UIImage imageNamed:@"delete-icon.png"] retain];
	prefs = [NSUserDefaults standardUserDefaults];
	

	
	[[self tableView] setBackgroundColor:[UIColor clearColor]];
	[[self tableView] setSeparatorColor:[UIColor clearColor]];
	[[self tableView] setScrollsToTop:[[prefs valueForKey:@"allow_status_bar_scroll"] boolValue]];	
	purchaseActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[purchaseActivity setHidesWhenStopped:YES];
	[purchaseActivity stopAnimating];

	settingsView = [[self view] retain];
	[self drawProSplashImage];
	[self drawTipsSplashImage];
}


// this is called from the AppDelegate once the purchase is finished.
- (void) stopPurchaseActivityIndicator
{
	[purchaseActivity stopAnimating];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SETTING_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView titleForHeaderInSection:section] != nil) {
        return SECTION_HEADER_HEIGHT;
    }
    else {
        // If no section header title, no section header needed
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
	
    // Create label with section title
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.frame = CGRectMake(20, 6, 300, 30);
    label.backgroundColor = [UIColor clearColor];
	label.textColor = [Resources cTitleColor];
//	label.textColor = [UIColor whiteColor];
//    label.textColor = [UIColor colorWithHue:(136.0/360.0)  // Slightly bluish green
//                                 saturation:1.0
//                                 brightness:0.60
//                                      alpha:1.0];
//    label.shadowColor = [UIColor whiteColor];
//    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.font = [UIFont boldSystemFontOfSize:16];
    label.text = sectionTitle;
	
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, SECTION_HEADER_HEIGHT)];
    [view autorelease];
    [view addSubview:label];
	
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	switch (section) {
		case SECTION_REDDIT_ACCOUNT:
			return @"Reddit Account";
			break;
		case SECTION_MESSAGE_FETCH:
			return @"Fetch New Messages";
			break;
		case SECTION_VIEWING_MESSAGE:
			return @"When viewing messages...";
			break;
		case SECTION_DISPLAY:
			return @"Display Preferences";
			break;
		case SECTION_FONTS:
			return @"Text Size";
			break;
		case SECTION_UPGRADE_PRO:
			if(![MKStoreManager isProUpgraded])
				return @"Upgrade to PRO";
			else
				return @"PRO Activated";
			break;
		case SECTION_FILTER:
			return @"Exclude posts that contain:";
			break;
		case SECTION_ADVANCED:
			return @"Advanced Settings";
			break;			
		case SECTION_CONTACT:
			return @"Get In Touch";
			break;
		case SECTION_HELP:
			return @"User Guide";
			break;
		case SECTION_ACKNOWLEDGEMENTS:
			return @"Acknowledgements";
			break;
			
		default:
			return nil;
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return nil;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	switch (section) {
		case SECTION_REDDIT_ACCOUNT:
			return NUM_ROWS_REDDIT_ACCOUNT;
			break;
		case SECTION_MESSAGE_FETCH:
			return NUM_ROWS_MESSAGE_FETCH;
			break;
		case SECTION_VIEWING_MESSAGE:
			return NUM_ROWS_VIEWING_MESSAGE;
			break;
		case SECTION_DISPLAY:
			return NUM_ROWS_DISPLAY;
			break;
		case SECTION_FONTS:
			return NUM_ROWS_FONTS;
			break;
		case SECTION_UPGRADE_PRO:
			if(![MKStoreManager isProUpgraded])
				return NUM_ROWS_UPGRADE_PRO;
			else
				return NUM_ROWS_UPGRADE_PRO - 1;
			break;
		case SECTION_FILTER:
			return [(NSMutableArray *) [prefs objectForKey:@"filterList"] count] + 1;
			break;
		case SECTION_ADVANCED:
			return NUM_ROWS_ADVANCED;
			break;
		case SECTION_CONTACT:
			return NUM_ROWS_CONTACT;
			break;
		case SECTION_HELP:
			return NUM_ROWS_HELP;
			break;
		case SECTION_ACKNOWLEDGEMENTS:
			return NUM_ROWS_ACKNOWLEDGEMENTS;
			break;
		default:
			return 0;
			break;
	}
	
}

- (UILabel *) createSettingNameLabelForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UILabel * settingLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 8, 300, 30)];
	[settingLabel setFont:[UIFont fontWithName:@"Helvetica" size:14]];
	[settingLabel setBackgroundColor:[UIColor clearColor]];
	[settingLabel setTextColor:[Resources cNormal]];
	NSString * label = @"";

	switch (indexPath.section) {
		case SECTION_REDDIT_ACCOUNT:
			if (indexPath.row == 0)
				label = @"Username";
			else if (indexPath.row == 1)
				label = @"Password";	
			break;
		case SECTION_MESSAGE_FETCH:
			if (indexPath.row == 0)
				label = @"Manually";
			else if (indexPath.row == 1)
				label = @"Every 2 Minutes";
			else if (indexPath.row == 2)
				label = @"Every 5 Minutes";
			else if (indexPath.row == 3)
				label = @"Every 10 Minutes";
			break;
		case SECTION_VIEWING_MESSAGE:
			if (indexPath.row == 0)
				label = @"Auto Mark As Read";
			break;
		case SECTION_FONTS:
			if (indexPath.row == 0)
				label = @"Small";
			else if (indexPath.row == 1)
				label = @"Medium";
			else if (indexPath.row == 2)
				label = @"Large";
			break;
		case SECTION_DISPLAY:
			if (indexPath.row == 0)
				label = @"Allow Rotation";
			else if (indexPath.row == 1)
				label = @"Status-Bar Tap Scrolling";
//			else if (indexPath.row == 2)
//				label = @"Show Quick-Scroll Buttons";
			else if (indexPath.row == 2)
				label = @"Enable Tilt-Scrolling";					
			else if (indexPath.row == 3)
				label = @"Reverse Tilt-Scroll Direction";
			else if (indexPath.row == 4)
				label = @"Show Thumbnails";				
			else if (indexPath.row == 5)
				label = @"Night Mode";	
			break;
		case SECTION_UPGRADE_PRO:
			if (indexPath.row == 0)
			{
				if(![MKStoreManager isProUpgraded])
					label = @"";
				else
					label = @"Thank you for upgrading.";					
				[settingLabel setTextColor:[UIColor orangeColor]];
			}
			else if (indexPath.row == 1)
			{
				label = @"PRO Features";
//				[settingLabel setNumberOfLines:5];
//				[settingLabel setFrame:CGRectMake(22, 8, 300, 90)];
//				[settingLabel setTextColor:[UIColor colorWithWhite:0.8 alpha:1]];
			}
			break;
		case SECTION_ADVANCED:
			if (indexPath.row == 0)
				label = @"Display Queue When Hiding Posts";				
			else if (indexPath.row == 1)
				label = @"Use Resized Imgur Images (Faster)";
			else if (indexPath.row == 2)
				label = @"Deeplink Imgur For Inline Viewing";

			break;
		case SECTION_CONTACT:
			if (indexPath.row == 0)
				label = @"Report a Bug";
			else if (indexPath.row == 1)
				label = @"Visit Online";
			break;
		case SECTION_HELP:
			if (indexPath.row == 0)
				label = @"         Power User Tips";
			else if (indexPath.row == 1)
				label = @"Show Help Icons";
			break;
		case SECTION_ACKNOWLEDGEMENTS:
			if (indexPath.row == 0)
				label = @"Reddit.com and the Reddit API";
			else if (indexPath.row == 1)
				label = @"JSON Framework by Stig Brautaset";
			else if (indexPath.row == 2)
				label = @"MKStoreKit by Mugunth Kumar";
			else if (indexPath.row == 3)
				label = @"Readability by Arc90";
		case SECTION_FILTER:
			if (indexPath.row < [(NSMutableArray *) [prefs objectForKey:@"filterList"] count])
				label = [(NSMutableArray *) [prefs objectForKey:@"filterList"] objectAtIndex:indexPath.row];
			break;
		default:
			break;
	}
	[settingLabel setText:label];	
	return settingLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == SECTION_CONTACT && indexPath.row == 2)
		return 110;
	else
		return 44;
}	

- (void) createInteractionForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{

	switch (indexPath.section) {
		case SECTION_REDDIT_ACCOUNT:
			if (indexPath.row == 0)
			{
				usernameField = [[UITextField alloc] initWithFrame:CGRectMake(130,12,170,24)];
				[usernameField setFont:[UIFont fontWithName:@"Helvetica" size:15]];
				[usernameField setTextAlignment:UITextAlignmentCenter];
				[usernameField setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
				[usernameField setDelegate:self];
				[usernameField setReturnKeyType:UIReturnKeyDone];
				[usernameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
				[usernameField setAutocorrectionType:UITextAutocorrectionTypeNo];
				[usernameField setTag:0];
				[usernameField setText:[prefs objectForKey:@"username"]];
				[cell addSubview:usernameField];
			}
			else if (indexPath.row == 1)
			{
				passwordField = [[UITextField alloc] initWithFrame:CGRectMake(130,12,170,24)];
				[passwordField setFont:[UIFont fontWithName:@"Helvetica" size:15]];
				[passwordField setTextAlignment:UITextAlignmentCenter];
				[passwordField setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
				[passwordField setReturnKeyType:UIReturnKeyDone];
				[passwordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
				[passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];				
				[passwordField setDelegate:self];
				[passwordField setTag:1];
				[passwordField setSecureTextEntry:YES];
				[passwordField setText:[prefs objectForKey:@"password"]];				
				[cell addSubview:passwordField];				
			}
			else if (indexPath.row == 2)
			{
				UIButton * authButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
				[authButton setTitle:@"Login" forState:UIControlStateNormal];
				[authButton setFrame:CGRectMake(130,12,170,24)];
				[authButton addTarget:self action:@selector(authorise:) forControlEvents:UIControlEventTouchUpInside];
				[authButton setTag:2];
				[cell addSubview:authButton];
				if ([redAPI authenticated])
				{
					UIImage * tickImage = [[UIImage imageNamed:@"green-tick-icon.png"] retain];
					UIImageView * tickView = [[UIImageView alloc] initWithImage:tickImage];
					[tickView setFrame:CGRectMake(270, 14, 20, 20)];
					[cell insertSubview:tickView atIndex:99];
				}

			}
			break;
		case SECTION_MESSAGE_FETCH:
			if (indexPath.row == [[prefs valueForKey:@"fetch_message_frequency"] intValue])
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			break;			
		case SECTION_FONTS:
			if (indexPath.row == [[prefs valueForKey:@"textsize"] intValue])
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			break;			
		case SECTION_VIEWING_MESSAGE:
			NSLog(@"");
			if ([[prefs valueForKey:@"auto_mark_as_read"] boolValue])
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			break;			
		case SECTION_DISPLAY:
			if ( (indexPath.row == 0 && [[prefs valueForKey:@"allow_rotation"] boolValue]) ||
				 (indexPath.row == 1 && [[prefs valueForKey:@"allow_status_bar_scroll"] boolValue]) ||
//				 (indexPath.row == 2 && [[prefs valueForKey:@"show_quick_scroll"] boolValue]) ||
				 (indexPath.row == 2 && [[prefs valueForKey:@"allow_tilt_scroll"] boolValue]) ||
				 (indexPath.row == 3 && [[prefs valueForKey:@"reverse_tilt_axis"] boolValue]) ||
				 (indexPath.row == 4 && [[prefs valueForKey:@"show_thumbs"] boolValue]) ||
				 (indexPath.row == 5 && [[prefs valueForKey:@"night_mode"] boolValue])
				)
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			
			if (indexPath.row == 2 && ![MKStoreManager isProUpgraded])
			{
				UIImageView * proLabelView = [[UIImageView alloc] initWithImage:proFeatureLabelImage];
				[proLabelView setFrame:CGRectMake(cell.bounds.size.width - 95, 19, 67, 10)];
				[cell addSubview:proLabelView];	
			}
			break;
		case SECTION_UPGRADE_PRO:
			if (indexPath.row == 0)
			{
				if([MKStoreManager isProUpgraded])
					[cell setAccessoryType:UITableViewCellAccessoryNone];
				else
					[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
				
				if ([[cell subviews] containsObject:purchaseActivity])
				{
					[purchaseActivity removeFromSuperview];
				}
				[purchaseActivity setFrame:CGRectMake([cell frame].size.width - 70, 10, 25, 25)];
				[cell addSubview:purchaseActivity];

				if(![MKStoreManager isProUpgraded])
				{
					UIImageView * upgradeNowLabelView = [[UIImageView alloc] initWithImage:upgradeNowLabel];
					[upgradeNowLabelView setFrame:CGRectMake(13, 10, 106, 26)];
					[cell addSubview:upgradeNowLabelView];
				}
			}
			break;
		case SECTION_ADVANCED:
			if ( (indexPath.row == 0 && [[prefs valueForKey:@"show_hide_queue"] boolValue]) ||
				 (indexPath.row == 1 && [[prefs valueForKey:@"use_lowres_imgur"] boolValue]) ||
				 (indexPath.row == 2 && [[prefs valueForKey:@"use_direct_imgur_link"] boolValue])
				)
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			break;
		case SECTION_CONTACT:
			[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
			if (indexPath.row == 2)
			{
				[cell setAccessoryType:UITableViewCellAccessoryNone];				
				UILabel * descLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 10, 280, 80)];
				[descLabel setText:@"Alien Blue is an open source project.  The source code is available from alienblue.org, and includes all PRO features.  We encourage developers to use the framework without restriction for non-commercial applications."];
				[descLabel setFont:[UIFont systemFontOfSize:13]];
				[descLabel setBackgroundColor:[UIColor clearColor]];
				[descLabel setNumberOfLines:10];
				[descLabel setTextColor:[UIColor colorWithWhite:0.8 alpha:1]];
				[cell addSubview:descLabel];
			}
			break;
		case SECTION_HELP:
			[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
			if (indexPath.row == 0)
			{
				UIImageView * starView = [[UIImageView alloc] initWithImage:starImage];
				[starView setFrame:CGRectMake(20, 7, 30, 30)];
				[cell addSubview:starView];	
			}
			else if (indexPath.row == 1)
			{
				if ([[prefs valueForKey:@"show_help_icon"] boolValue])
					[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
				else
					[cell setAccessoryType:UITableViewCellAccessoryNone];					
			}
			break;
		case SECTION_FILTER:
			if (indexPath.row == [(NSMutableArray *) [prefs objectForKey:@"filterList"] count])
			{
				newFilterField = [[UITextField alloc] initWithFrame:CGRectMake(24,12,290,24)];
				[newFilterField setFont:[UIFont boldSystemFontOfSize:15]];
				[newFilterField setTextAlignment:UITextAlignmentLeft];
				[newFilterField setBackgroundColor:nil];
				[newFilterField setTextColor:[UIColor whiteColor]];
				[newFilterField setReturnKeyType:UIReturnKeyDone];
				[newFilterField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
				[newFilterField setAutocorrectionType:UITextAutocorrectionTypeNo];				
				[newFilterField setDelegate:self];
				[newFilterField setTag:3];
				[newFilterField setText:@"Add a filter..."];				
				[cell addSubview:newFilterField];
//				UIButton * newFilterButton = [[UIButton buttonWithType:UIButtonTypeContactAdd] retain];
//				[newFilterButton setFrame:CGRectMake(20,12,30,24)];
//				[cell addSubview:newFilterButton];
			}
			else
			{
				UIButton * removeFilterButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];				
//				[removeFilterButton setImage:deleteImage forState:UIControlStateNormal];
				[removeFilterButton setFrame:CGRectMake(cell.bounds.size.width - 46
														,11,24,24)];
				[removeFilterButton setBackgroundColor:[UIColor clearColor]];
				[removeFilterButton setBackgroundImage:deleteImage forState:UIControlStateNormal];
				[removeFilterButton setTag:indexPath.row];
				[removeFilterButton addTarget:self action:@selector(removeFilterItem:) forControlEvents:UIControlEventTouchUpInside];
				[cell addSubview:removeFilterButton];
			}
			break;
			
		default:
			break;
	}	
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	
    static NSString *CellIdentifier = @"SettingCell";
	UITableViewCell * cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] init];
    }
	[cell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.3]];
	

	[cell addSubview:[self createSettingNameLabelForRowAtIndexPath:indexPath]];
	[self createInteractionForCell:cell atIndexPath:indexPath];
//	[cell addSubview:username];
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];

	// Fetch new messages section
	if (indexPath.section == SECTION_MESSAGE_FETCH)
	{
		[prefs setInteger:indexPath.row forKey:@"fetch_message_frequency"];
	}

	UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];	
	
	// When viewing messages...
	if (indexPath.section == SECTION_VIEWING_MESSAGE)
	{
		[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"auto_mark_as_read"];
	}	

	// Font size
	if (indexPath.section == SECTION_FONTS)
	{
		[prefs setInteger:indexPath.row forKey:@"textsize"];
	}	
	
	
	if (indexPath.section == SECTION_DISPLAY)
	{
		if (indexPath.row == 0)
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"allow_rotation"];
		else if (indexPath.row == 1)
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"allow_status_bar_scroll"];
//		else if (indexPath.row == 2)
//			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"show_quick_scroll"];
		else if (indexPath.row == 2)
		{
			if (![MKStoreManager isProUpgraded])
			{
				[MKStoreManager needProAlert];
				return;
			}			
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"allow_tilt_scroll"];
			if (![cell accessoryType])
			{
				NavigationController * nc = (NavigationController *) [self parentViewController];
				[nc activateTiltCalibrationMode];
			}
			
		}
		else if (indexPath.row == 3)
		{
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"reverse_tilt_axis"];			
		}

		else if (indexPath.row == 4)
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"show_thumbs"];
		
		else if (indexPath.row == 5)
		{
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"night_mode"];
			[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] refreshBackground];
		}		
		
	}
	
	if (indexPath.section == SECTION_UPGRADE_PRO)
	{
		if (indexPath.row == 0 && ![MKStoreManager isProUpgraded])
		{
			NSLog(@"upgrade now clicked");
			[purchaseActivity startAnimating];
//			[[MKStoreManager sharedManager] requestProductData];
			[[MKStoreManager sharedManager] buyProUpgrade];
		}
		else if (indexPath.row == 1)
		{
			[self showProSplash];
		}
	}


	if (indexPath.section == SECTION_ADVANCED)
	{
		if (indexPath.row == 0)
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"show_hide_queue"];
		else if (indexPath.row == 1)
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"use_lowres_imgur"];
		else if (indexPath.row == 2)
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"use_direct_imgur_link"];

	}	
	
	
	if (indexPath.section == SECTION_CONTACT)
	{
		if (indexPath.row == 0)
		{
			NSString * message = @"This will launch your Mail application and exit Alien Blue.  Do you want to continue?";
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report a Bug"
															message:message
														   delegate:self
												  cancelButtonTitle:@"No"
												  otherButtonTitles:@"Yes",nil];
			[alert setTag:1];
			[alert show];
			[alert release];			
		}
		else if (indexPath.row == 1)
		{
			NSString * message = @"This will launch Mobile Safari and exit Alien Blue.  Do you want to continue?";
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Visit AlienBlue.org"
															message:message
														   delegate:self
												  cancelButtonTitle:@"No"
												  otherButtonTitles:@"Yes",nil];
			[alert setTag:2];
			[alert show];
			[alert release];			
		}			
	}

	if (indexPath.section == SECTION_HELP)
	{
		if (indexPath.row == 0)
		{
			[self showTipsSplash];
		} 
		else if (indexPath.row == 1)
		{
			[prefs setBool:([cell accessoryType] != UITableViewCellAccessoryCheckmark) forKey:@"show_help_icon"];			
		}
	}
	
	
	[prefs synchronize];		
	[tableView reloadData];

}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}


- (void) correctSplashImageOrientation
{
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		[proSplashView setFrame:CGRectMake(65, 0, 415, 320)];
		[proSplashView setContentSize:CGSizeMake(320, 600)];
		[tipsView setFrame:CGRectMake(65, 0, 415, 320)];
		[tipsView setContentSize:CGSizeMake(320, 7400)];

	}
	else
	{
		[proSplashView setFrame:CGRectMake(0, 0, 320, 460)];
		[proSplashView setContentSize:CGSizeMake(320, 600)];
		[tipsView setFrame:CGRectMake(0, 0, 320, 460)];
		[tipsView setContentSize:CGSizeMake(320, 7400)];
	}
}

- (IBAction)hideSplash:(id)sender
{
	[self correctSplashImageOrientation];
	[self setView:settingsView];
	CGRect vFrame = [[self view] frame];
	vFrame.origin.x = 0;
	vFrame.origin.y	= 0;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		vFrame.size.width = [UIScreen mainScreen].applicationFrame.size.height;
	else
		vFrame.size.width = [UIScreen mainScreen].applicationFrame.size.width;
	[[self view] setFrame:vFrame];
}

- (void) showTipsSplash
{
	[self setView:tipsView];
	[self correctSplashImageOrientation];
	
}

- (void) showProSplash
{
	[self setView:proSplashView];
	[self correctSplashImageOrientation];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[[self tableView] reloadData];

	[self correctSplashImageOrientation];
	
//	if (fromInterfaceOrientation == UIInterfaceOrientationPortrait && ([self view] == proSplashView))
//	{
//		[proSplashView setFrame:CGRectMake(65, 0, 415, 320)];
//		[proSplashView setContentSize:CGSizeMake(320, 600)];
//	}
//	else
//	{
//		[proSplashView setFrame:CGRectMake(0, 0, 320, 460)];
//		[proSplashView setContentSize:CGSizeMake(320, 600)];
//	}
	
//	[self drawProSplashImage];
}

@end
