#import "NavigationController.h"
#import "AlienBlueAppDelegate.h"
#import "SettingsTableViewController.h"

@implementation NavigationController

@synthesize post;
@synthesize forcePortrait;
@synthesize shouldRefreshComments;
@synthesize shouldRefreshMessages;
@synthesize postsNavigation;
@synthesize browserView;
@synthesize commentsView;
@synthesize tiltCalibration;
@synthesize replyCommentID;
@synthesize isFullscreen;

static UIImage * up_icon;
static UIImage * down_icon;
static UIImage * up_icon_selected;
static UIImage * down_icon_selected;



- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
	NSLog(@"tab did change");
//	NSLog(@"tab did change to %@", [viewController class]);
	[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] hideConnectionErrorImage];	
}

-(void) loadNibs
{
	up_icon = [[UIImage imageNamed:@"vote-up-small.png"] retain];
	down_icon = [[UIImage imageNamed:@"vote-down-small.png"] retain];
	up_icon_selected = [[UIImage imageNamed:@"vote-up-selected-small.png"] retain];
	down_icon_selected = [[UIImage imageNamed:@"vote-down-selected-small.png"] retain];
	
	prefs = [NSUserDefaults standardUserDefaults];
	commentsView = [[CommentsTableViewController alloc] initWithNibName:@"CommentsView" bundle:nil];
	browserView = [[BrowserViewController alloc] initWithNibName:@"BrowserView" bundle:nil];
	[[self postsNavigation] setDelegate:self];
	redAPI = (RedditAPI *) [(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];
	shouldRefreshMessages = YES;
	
//	NSMutableDictionary * testPost = [[NSMutableDictionary alloc] init];
//	[self loadCommentsForPost:testPost];	
	exitFullscreenButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	[exitFullscreenButton setImage:[UIImage imageNamed:@"show-toolbars-button.png"] forState:UIControlStateNormal];
	[exitFullscreenButton addTarget:self action:@selector(exitFullscreenMode:) forControlEvents:UIControlEventTouchUpInside];

	backFullscreenButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	[backFullscreenButton setImage:[UIImage imageNamed:@"fullscreen-back-button.png"] forState:UIControlStateNormal];
	[backFullscreenButton addTarget:self action:@selector(goBackInFullscreen:) forControlEvents:UIControlEventTouchUpInside];
	
	
}	


- (void)viewDidLoad
{
	tiltCalibration = 0;
	tiltCalibrationModeActive = NO;
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
	[accel setDelegate:self];
	[accel setUpdateInterval:1.0f / 60.0f];
}


- (void) upvoteItem:(NSMutableDictionary *) item
{
	NSLog(@"-- upvotePost");
	if (![redAPI authenticated])
	{
		NSLog(@"cannot upvote :: unauthenticated (username %@)", [redAPI authenticatedUser]);
		[redAPI showAuthorisationRequiredDialog];
		return;
	}
	
	int previousVoteDirection = [[item valueForKey:@"voteDirection"] intValue];
	if (previousVoteDirection > 0)
	{
		[item setObject:[NSNumber numberWithInt:0] forKey:@"voteDirection"];
		[item setValue:[NSNumber numberWithInt:[[item valueForKey:@"score"] intValue] - 1] forKey:@"score"];
	}
	else
	{
		[item setObject:[NSNumber numberWithInt:1] forKey:@"voteDirection"];
		[item setValue:[NSNumber numberWithInt:[[item valueForKey:@"score"] intValue] + 1] forKey:@"score"];
	}
	[redAPI submitVote:item];
}

// In SDK 3.0, larger images loaded inline in comments cause corruption in the status bar
// and tab bar controller.  So we call this just in case.
- (void) redrawFrames
{
	NSLog(@"NavController :: Asked For Screen Refresh");
	[[self view] setNeedsDisplay];
}

- (void) downvoteItem:(NSMutableDictionary *) item
{
	NSLog(@"-- downvotePost");	
	if (![redAPI authenticated])
	{
		[redAPI showAuthorisationRequiredDialog];
		return;
	}
	
	int previousVoteDirection = [[item valueForKey:@"voteDirection"] intValue];
	if (previousVoteDirection < 0)
	{
		[item setObject:[NSNumber numberWithInt:0] forKey:@"voteDirection"];
		[item setValue:[NSNumber numberWithInt:[[item valueForKey:@"score"] intValue] + 1] forKey:@"score"];
	}
	else
	{
		[item setObject:[NSNumber numberWithInt:-1] forKey:@"voteDirection"];
		[item setValue:[NSNumber numberWithInt:[[item valueForKey:@"score"] intValue] - 1] forKey:@"score"];		
	}
	[redAPI submitVote:item];
	
}

- (IBAction)voteSegmentChanged:(id)sender 
{
	NSLog(@"segment changed");
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	NSString * segment = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
	
	// upvote
	if ([segmentedControl selectedSegmentIndex] == 0)
	{
		[self upvoteItem:post];
		[self refreshVotingSegment];
		return;
	}
	else if ([segmentedControl selectedSegmentIndex] == 2)
	{
		[self downvoteItem:post];		
		[self refreshVotingSegment];
		return;
	}


	UIViewController * previousViewController = [[postsNavigation viewControllers] objectAtIndex:[[postsNavigation viewControllers] count] - 2];	

	if ([segment isEqualToString:@"Comments"])
	{
		if ([previousViewController isKindOfClass:[PostsTableControllerView class]])	
		{
			// if we initially went directly to the browser before loading comments, we need to load
			// them now.
			[self loadCommentsForPost:post];
		} 
		else
		{
			// if we're coming back to the comments from the browser view (eg. from an embedded comment
			// link, we just pop back so that we don't lose our place in the comments.
			[postsNavigation popViewControllerAnimated:YES];
		}
	}
	else
	{
		// Handle the case when user navigaties "View Article -> Comments -> View Article"
		if ([previousViewController isKindOfClass:[BrowserViewController class]])	
		{
			[postsNavigation popViewControllerAnimated:YES];
		}
		else
			[self browseToLinkFromPost:post];
	}
	
	
	
	
}

- (void) clearAndRefreshPosts
{
	PostsTableControllerView * ptcv = (PostsTableControllerView *) [[postsNavigation viewControllers] objectAtIndex:0];
	[ptcv clearAndRefreshFromSettingsLogin];
}

- (void) replyToItem:(NSMutableDictionary *) item
{
	NSLog(@"-- reply to item in...");
	if (![item objectForKey:@"replyText"] || [[item valueForKey:@"replyText"] length] == 0)
	{
		NSLog(@"-- blank reply entered.. ignoring");
	}
	else
	{
		if ([item objectForKey:@"editMode"])
			[redAPI submitChangeReply:item withCallBackTarget:self];
		else
			[redAPI submitReply:item withCallBackTarget:self];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	NSLog(@"memory warning received in NavigationController");
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (IBAction)apiReplyResponse:(id)sender
{
	NSLog(@"apiReplyResponse in");
	NSString * newCommentID = (NSString *) sender;
	NSString * promptString = [NSString stringWithFormat:@"Your reply was submitted."];
	if ([self selectedViewController] == postsNavigation)
	{
		commentsView.navigationItem.prompt = promptString;
		[commentsView afterCommentReply:newCommentID];

		statusNotifyTimer = [NSTimer scheduledTimerWithTimeInterval:3
														 target:self
													   selector:@selector(clearStatus:)
													   userInfo:nil
														repeats:NO];	
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:promptString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
}

- (IBAction)clearStatus:(id)sender
{
	[postsNavigation visibleViewController].navigationItem.prompt = nil;
	
	if(statusNotifyTimer)
	{
		[statusNotifyTimer invalidate];
		statusNotifyTimer = nil;	
	}
}

- (void) refreshVotingSegment
{
	
//	if ([viewController isKindOfClass:[BrowserViewController class]])
//		NSLog(@"-- browser view voting segment");

		NSArray *segmentTextContent = [NSArray arrayWithObjects:
									   NSLocalizedString(@"Up", @""),
									   NSLocalizedString(@"", @""),
									   NSLocalizedString(@"Down", @""),
									   nil];

	votingSegment = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	[votingSegment addTarget:self
						  action:@selector(voteSegmentChanged:)
				forControlEvents:UIControlEventValueChanged];	
	[votingSegment setMomentary:NO];
	
	NSString * centerItem;
	if ([[postsNavigation visibleViewController] isKindOfClass:[CommentsTableViewController class]])
		centerItem = [NSString stringWithFormat:@"View %@",[[post valueForKey:@"type"] capitalizedString]];
	else if ([[postsNavigation visibleViewController] isKindOfClass:[BrowserViewController class]])
		centerItem = @"Comments";
	else
	{
//		[postsNavigation visibleViewController].navigationItem.titleView = nil;
		return;
	}
	
	
//	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	votingSegment.selectedSegmentIndex = -1;
	
	votingSegment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	votingSegment.segmentedControlStyle = UISegmentedControlStyleBar;
	//	UIBarButtonItem *segmentBarItem = [[[UIBarButtonItem alloc] initWithCustomView:segmentedControl] autorelease];

	UIImage * upIcon = up_icon;
	UIImage * downIcon = down_icon;
	
	if ([[post valueForKey:@"voteDirection"] intValue] > 0)
	{
		upIcon = up_icon_selected;
	} else if ([[post valueForKey:@"voteDirection"] intValue] < 0)
	{
		downIcon = down_icon_selected;
	}

	
	// We don't need the central item for self posts
	if ([centerItem isEqualToString:@"View Self"])
	{	
		centerItem = @"";
		[votingSegment setWidth:1 forSegmentAtIndex:1];
	}
	else
		[votingSegment setWidth:80 forSegmentAtIndex:1];	
	
	
	[votingSegment setWidth:52 forSegmentAtIndex:0];
	[votingSegment setWidth:52 forSegmentAtIndex:2];
	[votingSegment setImage:upIcon forSegmentAtIndex:0];
	[votingSegment setImage:downIcon forSegmentAtIndex:2];
	[votingSegment setTitle:centerItem forSegmentAtIndex:1];
	[postsNavigation visibleViewController].navigationItem.titleView = votingSegment;
	[votingSegment release];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	NSLog(@"*** refreshing voting segment for : %@", [viewController class]);
	if (isFullscreen)
		[self drawFullScreenBackButton];

	[self refreshVotingSegment];
}


-(void) loadCommentsForPost:(NSMutableDictionary *) npost
{
	NSLog(@"NavigationController::loadCommentsForPostId in()");

	// don't refresh comments if we're loading the same comment thread
	// incase the user accidentally clicked back (we don't want them to
	// lose their place in the comment thread
//	if (post && [[post valueForKey:@"name"] isEqualToString:[npost valueForKey:@"name"]])
//		shouldRefreshComments = NO;
//	else
//		shouldRefreshComments = YES;

	post = npost;
	[postsNavigation popToRootViewControllerAnimated:NO];
	[postsNavigation pushViewController:commentsView animated:YES];
	shouldRefreshComments = YES;
}

-(void) browse
{
	NSLog(@"browse in()");
}

-(void) browseToLinkFromPost:(NSMutableDictionary *) npost
{
	post = npost;
	if ([postsNavigation visibleViewController] != browserView)
		[postsNavigation pushViewController:browserView animated:YES];	
	[browserView browseToLink:[post valueForKey:@"url"] fromMessages:NO];
}

-(void) browseToPostThreadFromMessage:(NSMutableDictionary *) npost
{
	[self setShouldRefreshMessages:NO];	
	[self loadCommentsForPost:npost];
	[self setSelectedIndex:0];
}


-(void) browseToLinkFromMessage:(NSMutableDictionary *) link
{
	[self setShouldRefreshMessages:NO];
	if ([postsNavigation visibleViewController] != browserView)
		[postsNavigation pushViewController:browserView animated:YES];	
	[browserView browseToLink:[link valueForKey:@"url"] fromMessages:YES];
	//	browserView.navigationItem.titleView = nil;
	[self setSelectedIndex:0];
}

-(void) browseToLinkFromComment:(NSString *) link
{
	UIViewController * previousViewController = [[postsNavigation viewControllers] objectAtIndex:[[postsNavigation viewControllers] count] - 2];	
	if (previousViewController == browserView)
		[postsNavigation popViewControllerAnimated:YES];
	else if ([postsNavigation visibleViewController] != browserView)
		[postsNavigation pushViewController:browserView animated:YES];
	[browserView browseToLink:link fromMessages:NO];	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	
//	// don't allow rotation for settings
//	if ([self selectedIndex] == 2)
//		return NO;
	
	return [[prefs valueForKey:@"allow_rotation"] boolValue];		
//		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void)activateTiltCalibrationMode
{
	tiltCalibrationModeActive = YES;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	if (![[prefs valueForKey:@"allow_tilt_scroll"] boolValue])
		return;
	
	if (tiltCalibrationModeActive)
	{
		NSLog(@"Tilt Motion :: Calibrating");
		tiltCalibration = acceleration.z;
		tiltCalibrationModeActive = NO;
		return;
	}
	
	float tilt_threshold = 0.1f; //0.08f;
	float tilt_scroll_ratio = 9.0f;
	float max_accel = 0.6f;

	float acceleration_z;
	if (acceleration.z > 0)
	{
		acceleration_z = acceleration.z - tiltCalibration;// + tilt_threshold;
		if (acceleration_z > max_accel) acceleration_z = max_accel;
	}
	else
	{
		acceleration_z = acceleration.z - tiltCalibration;// - tilt_threshold;
		if (acceleration_z < (-1 * max_accel)) acceleration_z = -1 * max_accel;		
	}


//	NSLog(@"accelerometer in : %f", acceleration_z);

	if (fabs(acceleration.z - tiltCalibration) > tilt_threshold)
	{
		float direction = -1;
		if ([[prefs valueForKey:@"reverse_tilt_axis"] boolValue])
			direction = 1;
		
		float speed = direction * tilt_scroll_ratio * (acceleration_z);
//		NSLog(@"speed : %f", speed);		
		UIScrollView * scrollview;
		
		// try the posts/comments view first
		if ([self selectedIndex] == 0)
		{
			if ([postsNavigation visibleViewController] != browserView)
			{
				scrollview = (UIScrollView *) [[postsNavigation visibleViewController] view];

				CGPoint contentOffset = [scrollview contentOffset];
				contentOffset.y = contentOffset.y + speed;
				
				if ((contentOffset.y < -30 && speed < 0) || (contentOffset.y > [scrollview contentSize].height - 410 && speed > 0))
					return;
				else
					[scrollview setContentOffset:contentOffset animated:NO];
			}
		}
//		else if ([self selectedIndex] == 1 || [self selectedIndex] == 2)
//		{
//			scrollview = (UIScrollView *) [[self selectedViewController] view];			
//		}
	}
}

- (IBAction)showHelp:(id)sender 
{
	NSLog(@"showHelp in()");
	[self setSelectedIndex:2];
	SettingsTableViewController * settingsView = (SettingsTableViewController *) [[self viewControllers] objectAtIndex:2];
	[settingsView showTipsSplash];
}

- (void) drawFullScreenBackButton
{
	[backFullscreenButton removeFromSuperview];
	if ([[postsNavigation viewControllers] count] > 1)
	{
		CGRect bounds = [[self view] bounds];
		[backFullscreenButton setFrame:CGRectMake(0, bounds.size.height - 31, 43, 31)];
		[[self view] addSubview:backFullscreenButton];
	}
}

- (IBAction)goBackInFullscreen:(id)sender 
{
	if ([[postsNavigation viewControllers] count] > 1)
		[postsNavigation popViewControllerAnimated:YES];
}

- (IBAction)exitFullscreenMode:(id)sender 
{
	[exitFullscreenButton removeFromSuperview];
	[backFullscreenButton removeFromSuperview];
//	[self removeHideFullscreenButton];
	[[self tabBar] setHidden:NO];
	[postsNavigation setNavigationBarHidden:NO animated:YES];

	isFullscreen = NO;	
	
	if ([[postsNavigation visibleViewController] isMemberOfClass:[PostsTableControllerView class]])
		[(PostsTableControllerView *) [postsNavigation visibleViewController] refreshSegmentControl];

}


- (IBAction)enterFullscreenMode:(id)sender 
{
	
	[exitFullscreenButton removeFromSuperview];
	[[self tabBar] setHidden:YES];
	[postsNavigation setNavigationBarHidden:YES animated:YES];

	isFullscreen = YES;		
	
	if ([[postsNavigation visibleViewController] isMemberOfClass:[PostsTableControllerView class]])
		[(PostsTableControllerView *) [postsNavigation visibleViewController] refreshSegmentControl];
	CGRect bounds = [[self view] bounds];
	[exitFullscreenButton setFrame:CGRectMake(bounds.size.width / 2 - 83, bounds.size.height - 31, 166, 31)];
	[[self view] addSubview:exitFullscreenButton];
	
	[self drawFullScreenBackButton];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	NSLog(@"Post View rotated");
	if (isFullscreen)
		[self enterFullscreenMode:nil];
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


@end
