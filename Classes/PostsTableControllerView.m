//
//  PostsTableControllerView.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "PostsTableControllerView.h"
#import "NavigationController.h"
#import "AlienBlueAppDelegate.h"

@implementation PostsTableControllerView

@synthesize subreddit;
@synthesize segmentControl;
@synthesize subredditPickView;
@synthesize subredditManualEnterView;
@synthesize subredditScrollingPickerView;
@synthesize subredditManualText;
@synthesize subredditDoneButton;

static UIImage * proFeatureLabelImage;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void) enableProgressBar
{
	progressTimer = [NSTimer scheduledTimerWithTimeInterval:1
											 target:self
										   selector:@selector(updateProgressBar:)
										   userInfo:nil
											repeats:YES];
	
}



- (void) refreshRow:(int) row
{
	NSMutableArray * affectedRows = [[NSMutableArray alloc] init];
	NSIndexPath * ind = [NSIndexPath indexPathForRow:row inSection:0];
	[affectedRows addObject:ind];
	[[self tableView] reloadRowsAtIndexPaths:affectedRows withRowAnimation:UITableViewRowAnimationNone];
	[affectedRows release];
}

- (void) refreshProgressBar:(float) pr
{
	ProgressValue = pr;
	int row = [[self tableView] numberOfRowsInSection:0] - 1;
	[self refreshRow:row];
}

- (void) completeProgressBar
{
	[self refreshProgressBar:0.0];
	if(progressTimer)
	{
//		[progressTimer invalidate];
		progressTimer = nil;	
	}
}

-(void) updateProgressBar: (NSTimer *) theTimer
{
	if (ProgressValue <= 0.9)
	{
		[self refreshProgressBar:(ProgressValue + 0.05)];
	}
	else
	{
//		[theTimer invalidate];
		theTimer = nil;
	}
}

- (void) processHideQueue: (NSTimer *) theTimer
{
	int queue_length = [redAPI hideQueueLength];
	if (queue_length > 0)
	{
		if([[prefs valueForKey:@"show_hide_queue"] boolValue])
		{
			NSString * promptString = [NSString stringWithFormat:@"Hiding Posts (%d in queue)", queue_length];
			self.navigationItem.prompt = promptString;
		}
		[redAPI processFirstInPostQueue];
	}
	else
	{
		self.navigationItem.prompt = nil;
		[localHideQueue removeAllObjects];
	}
	
	// re-shift the floating front/subreddit/new segment control along
	// with the increased top navigation size
	[self refreshSegmentControl];
}

- (void) shiftSubredditManualFieldUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationBeginsFromCurrentState:YES];

	CGRect manual_view = [subredditManualEnterView frame];
	
	// The transform matrix
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -1 * manual_view.origin.y + 30);
	[subredditPickView setTransform:transform];
	[UIView commitAnimations];	
}

- (void) shiftSubredditManualFieldDown
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationBeginsFromCurrentState:YES];


	// The transform matrix
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 20);
	[subredditPickView setTransform:transform];
	[UIView commitAnimations];	
	
}

- (void) subredditPickerShouldShow:(BOOL) show
{
	CGRect redditPickFrame = [subredditPickView frame];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationBeginsFromCurrentState:YES];

	// this hack is required to fix the overlay of the pick view background
	// when switching to portrait view while choosing a subreddit.
	if (redditPickFrame.size.height == 504.0)
	{
		redditPickFrame.size.height = 664.0;
//		[subredditPickView setFrame:redditPickFrame];
	}
	
	
//	CGFloat shift = [[self view] frame].size.height + 40;
	CGFloat shift = redditPickFrame.size.height;
	if (!show)
		shift = shift * -1;
	else
		shift = 20;

	
	NSLog(@"shifting : %f", shift);
	
	// The transform matrix
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, shift);
	[subredditPickView setTransform:transform];
	[UIView commitAnimations];		
}

- (void) loadSubscribedSubreddits
{
	// load default subreddits for unauthenticated users
	if (![redAPI authenticated])
	{
		[subreddits release];
		subreddits = [[NSMutableArray alloc] init];
		[subreddits addObject:@"/r/announcements/"];
		[subreddits addObject:@"/r/AskReddit/"];
		[subreddits addObject:@"/r/blog/"];
		[subreddits addObject:@"/r/funny/"];
		[subreddits addObject:@"/r/gaming/"];
		[subreddits addObject:@"/r/pics/"];
		[subreddits addObject:@"/r/politics/"];
		[subreddits addObject:@"/r/programming/"];
		[subreddits addObject:@"/r/reddit.com/"];
		[subreddits addObject:@"/r/science/"];
		[subreddits addObject:@"/r/worldnews/"];
		[subreddits addObject:@"/r/WTF/"];
		[subredditScrollingPickerView reloadAllComponents];
		[subredditPickView setHidden:FALSE];
		[self subredditPickerShouldShow:YES];
		[[self segmentControl] setTitle:@"Subreddit" forSegmentAtIndex:1];
	}
	else
	{
		[redAPI fetchSubscribedRedditsWithCallBackTarget:self];
	}
}

- (IBAction) postCategorySegmentSelected:(id)sender 
{
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	NSString * segment = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
	if ([segment isEqualToString:@"Subreddit"])
	{
		[segmentedControl setTitle:@"Loading..." forSegmentAtIndex:1];
		[self loadSubscribedSubreddits];
		return;
	} else if ([segment isEqualToString:@"Saved"])
	{
		if (![redAPI authenticated])
		{
			[redAPI showAuthorisationRequiredDialog];
			return;
		}
		self.navigationItem.title = @"Saved Posts";
		subreddit = @"/saved/";
	} 
	else if ([segment isEqualToString:@"Hidden"])
	{
		if (![redAPI authenticated])
		{
			[redAPI showAuthorisationRequiredDialog];
			return;
		}
		self.navigationItem.title = @"Hidden Posts";
		if([prefs objectForKey:@"username"])
		{
			subreddit = [[NSString stringWithFormat: @"/user/%@/hidden/", [prefs stringForKey:@"username"]] retain];
		}
	}	
	else if ([segment isEqualToString:@"Front"])
	{
		self.navigationItem.title = @"Front Page";
		subreddit = @"";
	}
	else if ([segment isEqualToString:@"New"])
	{
		self.navigationItem.title = @"New";
		subreddit = @"/new/";
	}
	
	[posts removeAllObjects];
	[[self tableView] reloadData];
	[self fetchPosts:nil];	
}





- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (textField == [self subredditManualText])
	{
		[self shiftSubredditManualFieldUp];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == [self subredditManualText])
	{
		[self shiftSubredditManualFieldDown];
	}
	
}

// need this for the manual entry into subreddit
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSLog(@"textFieldShouldReturn in()");
	[textField resignFirstResponder];
	return NO;
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	NSLog(@"picker item selected");
	if (row == [subreddits count])
	{
		[subredditManualEnterView setHidden:FALSE];		
	}
	else
	{
		[subredditManualEnterView setHidden:TRUE];
	}
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
//	NSLog(@"numberOfComponentsInPickerView in");
//	return 1;
	return 1;
}

//PickerViewController.m
- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
//	return 5;
	return [subreddits count] + 1;
}		
		
- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	if (row == [subreddits count])
		return @"Other...";
	else
		return [subreddits objectAtIndex:row];
//	return @"hello";
	
//	return [arrayColors objectAtIndex:row];
}
		
		
- (IBAction)apiSubredditsResponse:(id)sender
{
	NSMutableDictionary *data = (NSMutableDictionary *) sender;

	NSArray * subreddit_response = 
		[[data objectForKey:@"data"] objectForKey:@"children"];

	if (subreddit_response) {
		[subreddits release];
		subreddits = [[NSMutableArray alloc] init];
		NSMutableArray * unsorted = [[NSMutableArray alloc] init];
		for (NSMutableDictionary * sr in subreddit_response)
		{
			[unsorted addObject:[[sr objectForKey:@"data"] valueForKey:@"url"]];
		}
		[subreddits addObjectsFromArray: [unsorted sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
		[unsorted release];
		NSLog(@"Imported %d Subreddits", [subreddits count]);
		[subredditScrollingPickerView reloadAllComponents];
		[subredditPickView setHidden:FALSE];
		[self subredditPickerShouldShow:YES];
		[[self segmentControl] setTitle:@"Subreddit" forSegmentAtIndex:1];
	}	
}

- (void) loadTestSubreddits
{
	SBJSON *parser = [[SBJSON alloc] init];
	
	NSString *jsonfile = [[NSBundle mainBundle] pathForResource:@"test-subreddits" ofType:@"json"];
	
	NSString *json_string = [[NSString alloc] initWithContentsOfFile:jsonfile];
	NSMutableDictionary *data = [parser objectWithString:json_string error:nil];
	[self apiSubredditsResponse:data];
}



- (void) positionSubredditPickFrameFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (fromInterfaceOrientation == UIInterfaceOrientationPortrait)
	{
		// the orientation is now landscape, and we need to resize the UIPickerView for the
		// limited vertical space.
		CGRect pickerFrame = [subredditScrollingPickerView frame];
		pickerFrame.size.width = 480;
		pickerFrame.size.height = 120;
		[subredditScrollingPickerView setFrame:pickerFrame];

		CGRect manualFrame = [subredditManualEnterView frame];
		manualFrame.origin.y = 180;
		[subredditManualEnterView setFrame:manualFrame];

		CGRect doneButtonFrame = [subredditDoneButton frame];
		doneButtonFrame.origin.y = 250;
		[subredditDoneButton setFrame:doneButtonFrame];
	}
	else
	{
		// orientation has moved from landscape back to portrait
		CGRect subredditFrame = [subredditPickView frame];
		NSLog(@"frame height: %f", subredditFrame.size.height);

		CGRect pickerFrame = [subredditScrollingPickerView frame];
		pickerFrame.size.width = 320;
		pickerFrame.size.height = 216;
		[subredditScrollingPickerView setFrame:pickerFrame];
		
		CGRect manualFrame = [subredditManualEnterView frame];
		manualFrame.origin.y = 300;
		[subredditManualEnterView setFrame:manualFrame];
		
		CGRect doneButtonFrame = [subredditDoneButton frame];
		doneButtonFrame.origin.y = 380;
		[subredditDoneButton setFrame:doneButtonFrame];
	}
}

- (IBAction)scrollingSegmentChanged:(id)sender
{
	NSLog(@"scrolling segment changed");
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
//	NSString * segment = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
	if ([segmentedControl selectedSegmentIndex] == 0)
		[[self tableView] scrollRectToVisible:CGRectMake(0,0,1,1) animated:YES];
	else if ([segmentedControl selectedSegmentIndex] == 1)
	{
		NSIndexPath * ind = [NSIndexPath indexPathForRow:[posts count] inSection:0];
		[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}


//	segmentedControl.selectedSegmentIndex = -1;
//	[segmentedControl setSelectedSegmentIndex:-1];
}


- (void) createScrollingSegment
{
	
	NSArray * segmentTextContent = [NSArray arrayWithObjects:
								   NSLocalizedString(@"Up", @""),
								   NSLocalizedString(@"Down", @""),
								   nil];
	scrollSegmentControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	[scrollSegmentControl addTarget:self
					  action:@selector(scrollingSegmentChanged:)
			forControlEvents:UIControlEventValueChanged];	

	[scrollSegmentControl setMomentary:YES];
//	scrollSegmentControl.selectedSegmentIndex = -1;
	scrollSegmentControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	scrollSegmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
	
	UIImage * up_icon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"top-scroll" ofType:@"png"]];
	UIImage * down_icon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bottom-scroll" ofType:@"png"]];
	
	[scrollSegmentControl setWidth:30 forSegmentAtIndex:0];
	[scrollSegmentControl setWidth:30 forSegmentAtIndex:1];
	[scrollSegmentControl setImage:up_icon forSegmentAtIndex:0];
	[scrollSegmentControl setImage:down_icon forSegmentAtIndex:1];
	UIBarButtonItem *segmentBarItem = [[[UIBarButtonItem alloc] initWithCustomView:scrollSegmentControl] autorelease];	
	self.navigationItem.leftBarButtonItem = segmentBarItem;
	[scrollSegmentControl release];	
}

- (void) removeSegmentControl
{
	[segmentControl removeFromSuperview];
}

- (void) refreshSegmentControl
{
	[self removeSegmentControl];
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];

	// no need to draw the segment control if we're in fullscreen mode.
	// or if we're not on the PostsNavigation tab
	if ([nc isFullscreen] || [nc selectedIndex] != 0)
		return;
	
	CGRect segmentFrame = [segmentControl frame];
	segmentFrame.origin.y = [[[self navigationController] navigationBar] frame].size.height + 18;

	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		segmentFrame.size.width = [[[UIApplication sharedApplication] keyWindow] frame].size.height;
	else
		segmentFrame.size.width = [[[UIApplication sharedApplication] keyWindow] frame].size.width;	
	[segmentControl setFrame:segmentFrame];
//	[[nc view] addSubview:segmentControl];		
	[[nc view] insertSubview:segmentControl belowSubview:subredditPickView];
    [[self tableView] setContentInset:UIEdgeInsetsMake(24,0,0,0)];
//	[[self tableView] setContentOffset:contentOffset];
	//	contentOffset.y = -50;
	//	[scrollview setContentOffset:contentOffset animated:NO];
	
}



- (void)viewDidLoad {
	NSLog(@"table view loaded");
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];

	proFeatureLabelImage = [[UIImage imageNamed:@"pro-feature-label.png"] retain];
    [super viewDidLoad];
	prefs = [NSUserDefaults standardUserDefaults];
	ProgressValue = 0;
	resultsFetched = NO;
	redAPI = [(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];

//	[[self.navigationController navigationItem] setPrompt:@"Hello"];
//	[[self.navigationController 
//	
//
	timer = [NSTimer scheduledTimerWithTimeInterval:2
													 target:self
												   selector:@selector(processHideQueue:)
												   userInfo:nil
													repeats:YES];
	
	
	// if the subreddit variable has not been set, default to the front page.
	if (!subreddit)
	{
		subreddit = @"";
	}

	[segmentControl addTarget:self
						 action:@selector(postCategorySegmentSelected:)
			   forControlEvents:UIControlEventValueChanged];

//
//	UIScrollView * scrollview = (UIScrollView *) [[self tableView] superview];
//	CGRect tableFrame = [scrollview frame];
//	tableFrame.origin.y = 300;
//	[scrollview setFrame:tableFrame];
//	CGPoint contentOffset = [scrollview contentOffset];
//	contentOffset.y = -50;
//	[scrollview setContentOffset:contentOffset animated:NO];

	//	CGRect tableFrame = [[self tableView] scr
//	tableFrame.origin.y = 262;
//	tableFrame.size.height -= 62;
//	[[self tableView] setFrame:tableFrame];
	
	NSLog(@"segment set");

	[subredditPickView setHidden:TRUE];
	[self subredditPickerShouldShow:NO];

	[[[[self parentViewController] parentViewController] view] addSubview:subredditPickView];	
	
	
	UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"Posts" style: UIBarButtonItemStyleBordered target: nil action: nil];
	[[self navigationItem] setBackBarButtonItem: newBackButton];
	[newBackButton release];
	
	localHideQueue = [[NSMutableArray alloc] init];


	
	introButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info-icon.png"] style:UIBarButtonItemStyleBordered target:nc action:@selector(showHelp:)];	

	fullscreenButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"fullscreen-icon.png"] style:UIBarButtonItemStyleBordered target:nc action:@selector(enterFullscreenMode:)];		
	//	[[[self parentViewController] view] addSubview:subredditPickView];
	
	
//	NSString * background_file = [[NSBundle mainBundle] pathForResource:@"background-blue" ofType:@"png"];	
//	UIImage * background = [[UIImage alloc] initWithContentsOfFile:background_file];
//	[[self view] setBackgroundImage:background forState:UIControlStateNormal];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
//	[self.editButtonItem setTitle:@"Hide"];

//	[(NavigationController *) [[self navigationController] tabBarController] loadCommentsForPostId:@"myID!"];

//	NavigationController * nc = (NavigationController *) [self parentViewController];
//	[nc loadCommentsForPostId:@"bonv4"];
	
	self.navigationItem.title = @"Front Page";	
	[self fetchPosts:nil];
	
}



- (void)viewWillAppear:(BOOL)animated {
//	[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

	[segmentControl setHidden:NO];	
	
	// refresh look of visible rows (e.g. if we come back after change to night-mode)
	[[self tableView] reloadRowsAtIndexPaths:[[self tableView] indexPathsForVisibleRows] withRowAnimation:NO];	
	

	
//	if ([[prefs valueForKey:@"show_quick_scroll"] boolValue])	
//		[self createScrollingSegment];
//	else
	self.navigationItem.leftBarButtonItem = fullscreenButton;

	if ([[prefs valueForKey:@"show_help_icon"] boolValue])		
		[[self navigationItem] setRightBarButtonItem:introButton];
	else
		self.navigationItem.rightBarButtonItem = nil;

	[self refreshSegmentControl];	
	
	[[self tableView] setScrollsToTop:[[prefs valueForKey:@"allow_status_bar_scroll"] boolValue]];	
}


- (void)viewWillDisappear:(BOOL)animated {
//	[self.navigationController setNavigationBarHidden:NO animated:animated];

	[segmentControl setHidden:YES];
	
	[super viewWillDisappear:animated];
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return NO;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	NSLog(@"memory warning received in PostsTableController");
	[ImageCache resetImageCache];
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [posts count] + 1;
}

- (UITableViewCell *) createViewMoreCell
{
	UITableViewCell * moreCell = [[UITableViewCell alloc] init];

	// this is necessary to allow correct centering of HideAll and ShowMore buttons
	// when rotating the device.
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		[moreCell setFrame:CGRectMake(0, 0, 390, 300)];
	else
		[moreCell setFrame:CGRectMake(0, 0, 320, 300)];		
	
	
	[moreCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	UIButton * showMoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	CGRect buttonFrame = CGRectMake(100, 25, 200, 40);
	[showMoreButton setFrame:buttonFrame];
	UIProgressView * progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	CGRect progressFrame = CGRectMake(60, 75, 200, 40);
	[progress setFrame:progressFrame];


//	if ([posts count] == 0 && [redAPI hideQueueLength] == 0)
	if ([redAPI loadingMessages])	
		[showMoreButton setTitle:@"Loading..." forState:UIControlStateNormal];
	else
		[showMoreButton setTitle:@"Show more..." forState:UIControlStateNormal];
	[showMoreButton setTitleColor:[Resources cNormal] forState:UIControlStateNormal];
	[showMoreButton setTitleColor:[Resources cTitleColor] forState:UIControlStateDisabled];
	[showMoreButton setBackgroundImage:[Resources barImage] forState:UIControlStateNormal];

	
	
	[showMoreButton addTarget:self action:@selector(fetchPosts:) forControlEvents:UIControlEventTouchUpInside];					
	[moreCell addSubview:showMoreButton];

	// hide the progress bar when it isn't in use.
//	if (ProgressValue > 0.0 && ProgressValue < 1.0)
	if([redAPI loadingPosts])
	{
		[progress setHidden:NO];	
		[progress setProgress:ProgressValue];
		[showMoreButton setEnabled:FALSE];
	}
	else
	{
		[showMoreButton setEnabled:TRUE];		
		[progress setHidden:YES];

		if (![MKStoreManager isProUpgraded])
		{
			UIImageView * proLabelView = [[UIImageView alloc] initWithImage:proFeatureLabelImage];
			[proLabelView setFrame:CGRectMake(38, 76, 67, 10)];
			[proLabelView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
			[moreCell addSubview:proLabelView];	
		}
	}

	[progress setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];	
	[moreCell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[moreCell addSubview:progress];	

	UIButton * hideAllButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[hideAllButton addTarget:self action:@selector(hideAll:) forControlEvents:UIControlEventTouchUpInside];
	[hideAllButton setTitle:@"Hide All" forState:UIControlStateNormal];

	// in night mode, the hide button needs to be modified so that the white background
	// doesn't stick out like a sore thumb
	if ([prefs boolForKey:@"night_mode"])
	{
		[hideAllButton setBackgroundImage:[Resources barImage] forState:UIControlStateNormal];
		[hideAllButton setTitleColor:[Resources cTitleColor] forState:UIControlStateNormal];
	}
	
	
//	[hideAllButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
//	[showMoreButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];

	[hideAllButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[showMoreButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];

	
	// disable "Hide All" feature when browsing Hidden or Saved Posts:
	if (![subreddit isEqualToString:@""] &&
		[subreddit rangeOfString:@"/r/" options:NSCaseInsensitiveSearch].location == NSNotFound)
	{
		[hideAllButton setEnabled:NO];
//		[hideAllButton setBackgroundColor:[UIColor grayColor]];
	}
	else
	{
		[hideAllButton setEnabled:YES];
//		[hideAllButton setBackgroundColor:[UIColor whiteColor]];
	}
	
	
	buttonFrame.origin.x = 20;
	buttonFrame.size.width = 100;
	[hideAllButton setFrame:buttonFrame];
	[moreCell addSubview:hideAllButton];
	return moreCell;
}

- (UITableViewCell *) createNothingHereCell
{
	UITableViewCell * nCell = [[UITableViewCell alloc] init];
	UILabel * nothingHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 25, 200, 40)];
	[nothingHereLabel setTextAlignment:UITextAlignmentCenter];
	[nothingHereLabel setText:@"Nothing here."];
	[nothingHereLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[nothingHereLabel setBackgroundColor:[UIColor clearColor]];
	[nothingHereLabel setTextColor:[UIColor whiteColor]];
	[nothingHereLabel setFont:[UIFont systemFontOfSize:19]];
	[nCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[nCell addSubview:nothingHereLabel];
	[nCell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	return nCell;
}

#define ASYNC_IMAGE_TAG 9999

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	// empty set
	if (indexPath.row == 0 && [posts count] == 0 && resultsFetched && [redAPI hideQueueLength] == 0)
	{
		return [self createNothingHereCell];
	}
	
	if (indexPath.row == [posts count])
		return [self createViewMoreCell];
	
	NSString * CellIdentifier = @"FastPostCell";

	NSMutableDictionary * post = [posts objectAtIndex:indexPath.row];	
	
	PostCell *cell = (PostCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];


	if (cell == nil) {
		cell = [[[PostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.frame = CGRectMake(0.0, 0.0, 320.0, 100);
		
	}
	
	[cell setTag:indexPath.row];
	[cell setPostController:self];
	[cell setPost:post];

    return cell;
}


//
//// Customize the appearance of table view cells.
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//	// empty set
//	if (indexPath.row == 0 && [posts count] == 0 && resultsFetched && [redAPI hideQueueLength] == 0)
//	{
//		return [self createNothingHereCell];
//	}
//	
//	if (indexPath.row == [posts count])
//		return [self createViewMoreCell];
//	
//    static NSString *CellIdentifier = @"customCell";
//	PostCell * cell = (PostCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//	if (cell == nil) {
//		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CustomPostCell" owner:nil options:nil];		
//		for(id currentObject in topLevelObjects)
//		{
//			if([currentObject isKindOfClass:[PostCell class]])
//			{
//				cell = (PostCell *)currentObject;
//				break;
//			}
//		}
//    }
//	NSDictionary * p = [posts objectAtIndex:indexPath.row];
//	[[cell titleText] setText:[p objectForKey:@"title"]];
//	[[cell subreddit] setText:[p objectForKey:@"subreddit"]];
//	[[cell points] setText:[[p objectForKey:@"score"] stringValue]];	
//	[[cell domain] setText:[p objectForKey:@"domain"]];	
//	
////	[[cell num_comments] setText:[NSString stringWithFormat: @"%d comment(s)", [[p objectForKey:@"num_comments"] intValue]]];	
//	
//	[[cell viewForBackground] setBackgroundColor:[UIColor clearColor]];
//
//	[[cell commentsButton] setTitle:[NSString stringWithFormat: @"%d comment(s)", [[p objectForKey:@"num_comments"] intValue]] forState:UIControlStateNormal];	
//	[[cell commentsButton] setTag:indexPath.row];
//	[[cell commentsButton] addTarget:self action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
//
//    return cell;
//}

- (void) showCommentsForPost:(NSMutableDictionary *) post
{
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[nc loadCommentsForPost:post];	
}

//- (IBAction)showComments:(id)sender 
//{
//	NSLog(@"showComments in()");
//	UIButton *button = (UIButton *)sender;	
//	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//	NSDictionary * post = [posts objectAtIndex:[button tag]];
//
////	[nc loadCommentsForPostId:[post objectForKey:@"id"]];
//	[nc loadCommentsForPost:post];	
//}


- (void) openLinkForPost:(NSMutableDictionary *) post
{
	NSLog(@"open link clicked");
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];

	if ([RedditAPI isSelfLink:[post valueForKey:@"domain"]])
	{
		[nc loadCommentsForPost:post];
	}
	else
	{
		[nc browseToLinkFromPost:post];
	}
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];

	
	// This check is necessary, as the "Show more..." cell is the last cell in the table
	// and shouldn't be selected.
//	if (indexPath.row < [posts count])
//	{
//		NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//		NSMutableDictionary * post = [posts objectAtIndex:indexPath.row];
//		NSRange range = [[post valueForKey:@"domain"] rangeOfString : @"self."];
//		if (range.location != NSNotFound) {
//			[nc loadCommentsForPost:post];
//		}
//		else
//		{
////			NSString * url = [post objectForKey:@"url"];
////			[nc setPostId:[[post valueForKey:@"id"] copy]];
//			[nc browseToLinkFromPost:post];
//		}
//		
//
////		[tableView reloadData];
////		PostCell * cell = (PostCell * ) [tableView cellForRowAtIndexPath:indexPath];
////		[[cell viewForBackground] setBackgroundColor:[[UIColor alloc] initWithRed:20.0 / 255 green:59.0 / 255 blue:102.0 / 255 alpha:0.3]];
//////		[[cell buttonToolbar] setHidden:NO];
//		NSLog(@"Selected Row %d", indexPath.row);
//	}
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.

	// don't allow swipe-to-hide if the we're viewing Hidden or Saved Posts:
	if (![subreddit isEqualToString:@""] &&
	   [subreddit rangeOfString:@"/r/" options:NSCaseInsensitiveSearch].location == NSNotFound)
		return NO;
	
	if (indexPath.row < [posts count])
		return YES;
	else
		return NO;
}


- (void) hideSinglePost:(NSMutableDictionary *) post
{
	// Delete the row from the data source
	NSLog(@"-- hiding post: %@", [post valueForKey:@"name"]);
	int row = [posts indexOfObject:post];
	if (row == NSNotFound)
		return;
	
//	NSDictionary * post = [posts objectAtIndex:indexPath.row];
	[redAPI addPostToHideQueue:[post valueForKey:@"name"]];		
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:0];
	[posts removeObjectAtIndex:indexPath.row];
	[[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	[[self tableView] reloadData];
}

 //Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self hideSinglePost:[posts objectAtIndex:indexPath.row]];
//		[self hidePostAtRow:indexPath.row];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
	[posts release];
    [super dealloc];
}


- (BOOL) shouldFilterOutPost:(NSMutableDictionary *) post
{
	NSMutableArray * filterList = (NSMutableArray *) [prefs objectForKey:@"filterList"];
	if (!filterList || [filterList count] == 0)
		return NO;
	
	NSString * postTitle = [post valueForKey:@"title"];
	for (NSString * filterItem in filterList)
	{
		if ([postTitle rangeOfString:filterItem options:NSCaseInsensitiveSearch].location != NSNotFound)		
			return YES;
	}
	
	return NO;
}

- (IBAction)apiPostsResponse:(id)sender
{

	NSMutableDictionary *data = (NSMutableDictionary *) sender;
	
	for (NSDictionary * post_data in [[data objectForKey:@"data"] objectForKey:@"children"])
	{
		NSMutableDictionary * post = [post_data objectForKey:@"data"];
		// we check if the incoming posts are in the hide queue because Reddit may not
		// yet have been notified that the user doesn't want to see the particular post.
		// due to delays in rate-limiting.
		//		if (![redAPI isPostInHideQueue:[post valueForKey:@"name"]])
		if (![localHideQueue containsObject:[post valueForKey:@"name"]] 
			&& ![self shouldFilterOutPost:post]
			)
		{
			[Resources processPost:post];
	
			// start caching thumbnail
			if([prefs boolForKey:@"show_thumbs"])
				[ImageCache imageForURL:[post valueForKey:@"thumbnail"] withCallBackTarget:nil];
			
			[posts addObject:post];
		}
	}
	
//	[posts addObjectsFromArray:[[data objectForKey:@"data"] objectForKey:@"children"]];
	
	NSLog(@"Imported %d", [posts count]);

	[[self tableView] reloadData];
	[self completeProgressBar];
	resultsFetched = YES;
}


- (void) loadTestPosts
{
	SBJSON *parser = [[SBJSON alloc] init];
	
	NSString *jsonfile = [[NSBundle mainBundle] pathForResource:@"home" ofType:@"json"];
	
	NSString *json_string = [[NSString alloc] initWithContentsOfFile:jsonfile];
	NSMutableDictionary *data = [parser objectWithString:json_string error:nil];
	[self apiPostsResponse:data];
}

- (void) clearAndRefreshFromSettingsLogin
{
	[posts removeAllObjects];
	[[self tableView] reloadData];
	[self fetchPosts:nil];	
}

- (IBAction) hideAll:(id)sender
{
	if (![MKStoreManager isProUpgraded])
	{
		[MKStoreManager needProAlert];
		return;
	}
	
	if (![redAPI authenticated])
	{
		[redAPI showAuthorisationRequiredDialog];
		return;
	}

	

	for (NSDictionary * post in posts)
	{
		[redAPI addPostToHideQueue:[post valueForKey:@"name"]];
		[localHideQueue addObject:[post valueForKey:@"name"]];
	}
	[posts removeAllObjects];
	[[self tableView] reloadData];

	// load a fresh set of results
	[self fetchPosts:nil];
}


- (IBAction) fetchPosts:(id)sender
{
	resultsFetched = NO;
	
	[self enableProgressBar];
	NSLog(@"Show more ...");
	NSString * afterPostID = @"";
	if (!posts)
	{
		posts = [[NSMutableArray alloc] init];
	}

	if (posts && [posts count] > 0)
	{
		NSDictionary * lastPost = [posts objectAtIndex:([posts count] - 1)];
		afterPostID = [lastPost valueForKey:@"name"];
		NSLog(@"asking for posts after id [%@] in subreddit [%@]", afterPostID, subreddit);
	}

	[redAPI fetchPostsForSubreddit:subreddit afterPostID:afterPostID callBackTarget:self];

	[[self tableView] reloadData];
}



- (IBAction)loadPosts:(id)sender
{
	NSLog(@"Load Posts Clicked!");
//	[self refreshProgressBar:0.5];
//	[self enableProgressBar];
	
//	RedditAPI * redAPI = [(NeuRedditAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];
//	[redAPI fetchPostsForSubreddit:@"" afterPostID:@"" callBackTarget:self];
	
	
//	
//	[posts release];
//	posts = [[NSMutableArray alloc] init];
//	
//	SBJSON *parser = [[SBJSON alloc] init];
//	
//	NSString *jsonfile = [[NSBundle mainBundle] pathForResource:@"home" ofType:@"json"];
//	
//	NSString *json_string = [[NSString alloc] initWithContentsOfFile:jsonfile];
//	NSMutableDictionary *data = [parser objectWithString:json_string error:nil];
//
//	[posts addObjectsFromArray:[[data objectForKey:@"data"] objectForKey:@"children"]];
//	
//	NSLog(@"Imported %d", [posts count]);
//
//	NSDictionary * p = [[posts objectAtIndex:20] objectForKey:@"data"];	
//	NSLog([p objectForKey:@"title"]);
//	
//	
////	for (int i=0; i<50; i++) {
////		Post *post = [[Post alloc] init];
////		NSString *s = [NSString stringWithFormat: @"Title : %d", i];		
////		[post setTitleText:@"title "];
////		[post setAuthor:@"author name!"];
////		[posts addObject:post];
////	}
//	[self.tableView reloadData];
}

- (NSString *) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return @"Hide Post";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// empty set
	if (indexPath.row == 0 && [posts count] == 0 && resultsFetched && [redAPI hideQueueLength] == 0)
		return 150;

	if (indexPath.row == [posts count])
		return 150;

	float cs = 0;
	CGSize constraintSize = CGSizeMake([[self tableView] frame].size.width - 45, MAXFLOAT);
	NSMutableDictionary * post = [posts objectAtIndex:indexPath.row];
	CGSize labelSize = [[post valueForKey:@"title"] sizeWithFont:[Resources mainFont] constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	cs += labelSize.height;
	cs += 120;
	return cs;
	
}	

- (IBAction) textFieldDone: (id) sender
{
	[sender resignFirstResponder];	
}

- (IBAction)cancelSubredditSelect:(id)sender
{
	[self subredditPickerShouldShow:NO];
	[[self segmentControl] setTitle:@"Subreddit" forSegmentAtIndex:1];
}

- (IBAction)chooseSubredditButton:(id)sender
{
	NSLog(@"choose subreddit button in()");
	[subredditManualText resignFirstResponder];
	[self shiftSubredditManualFieldDown];
	int row = [subredditScrollingPickerView selectedRowInComponent:0];

	// custom reddit entered
	if (row == [subreddits count])
	{
		NSString * custom = [[self subredditManualText] text];
		int slash_location = [custom rangeOfString:@"/" options:NSCaseInsensitiveSearch].location;
		// append a "/" if the user didn't enter it in.
		// the slash_location == 0 check is used to handle entry like /pics/ (with prepending /)
		if (slash_location == NSNotFound || slash_location == 0)
			custom = [custom stringByAppendingString:@"/"];
		custom = [@"/r/" stringByAppendingString:custom];
		subreddit = [custom copy];
	}
	else
	{
		subreddit = [subreddits objectAtIndex:row]; 
	}
	self.navigationItem.title = subreddit;	
	[self subredditPickerShouldShow:NO];
	[posts removeAllObjects];
	[[self tableView] reloadData];
	[self fetchPosts:nil];	
	NSLog(@"Selected Subreddit : %@", subreddit);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	NSLog(@"Post View rotated");
	[self refreshSegmentControl];	

	[self positionSubredditPickFrameFromOrientation:fromInterfaceOrientation];
	[[self tableView] reloadRowsAtIndexPaths:[[self tableView] indexPathsForVisibleRows] withRowAnimation:NO];	
}

@end

