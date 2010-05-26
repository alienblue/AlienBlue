//
//  CommentsTableViewController.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 29/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "CommentsTableViewController.h"
#import "NavigationController.h"
#import "AlienBlueAppDelegate.h"

@implementation CommentsTableViewController

@synthesize flatComments, savedSearchTerm, savedScopeButtonIndex, searchWasActive;

float CommentsLoadProgressValue = 0;

- (void) scrollToRow:(int) row
{
	NSIndexPath * ind = [NSIndexPath indexPathForRow:row inSection:0];
	[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void) clearHeightCacheForRow:(int) row
{
	[bodyHeightCache replaceObjectAtIndex:row withObject:[NSNumber numberWithFloat:-1]];	
}

- (void) refreshRow:(int) row
{
	NSMutableArray * affectedRows = [[NSMutableArray alloc] init];
	NSIndexPath * ind = [NSIndexPath indexPathForRow:row inSection:0];
	[affectedRows addObject:ind];
	[[self tableView] reloadRowsAtIndexPaths:affectedRows withRowAnimation:UITableViewRowAnimationNone];
	[affectedRows release];
}


- (void) enableProgressBar
{
	CommentsLoadProgressValue = 0;
	progressTimer = [NSTimer scheduledTimerWithTimeInterval:1
											 target:self
										   selector:@selector(updateProgressBar:)
										   userInfo:nil
											repeats:YES];
	
}

- (void) refreshProgressBar:(float) pr
{
	CommentsLoadProgressValue = pr;
	int row = [[self tableView] numberOfRowsInSection:0] - 1;
	[self refreshRow:row];	
}

- (void) completeProgressBar
{
	[self refreshProgressBar:0.0];
	if (progressTimer)
	{
//		[progressTimer invalidate];
		progressTimer = nil;
	}
}

-(void) updateProgressBar: (NSTimer *) theTimer
{
	if (CommentsLoadProgressValue <= 0.9)
	{
		[self refreshProgressBar:(CommentsLoadProgressValue + 0.14)];
	}
	else
	{
//		[theTimer invalidate];
		theTimer = nil;
	}
}

- (NSMutableArray *) parseBodyForUndescribedLinks:(NSMutableDictionary *) comment
{
	NSMutableString * body = [[comment valueForKey:@"body"] copy];	
//	NSMutableArray * links = [[NSMutableArray alloc] init];
	NSMutableArray * links = [NSMutableArray arrayWithCapacity:0];
	int bodyLength = [body length];
	int pos = 0;
	int start_link_pos = 0;
	int end_link_pos = 0;
	int link_counter = 0;
	BOOL linksAvailable = TRUE;
//	NSLog(@"Body Text: %@",body);
	while (linksAvailable) {	
		start_link_pos = [body rangeOfString:@"http://" options:NSCaseInsensitiveSearch range:NSMakeRange (pos, bodyLength - pos)].location;
		end_link_pos = [body rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange (start_link_pos, bodyLength - start_link_pos)].location;
		// also try newline character if space is not found
		int new_line_pos = [body rangeOfString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange (start_link_pos, bodyLength - start_link_pos)].location;
		// use the one that is closest to the http
		if (new_line_pos != NSNotFound)
		{
			if (new_line_pos < end_link_pos)
				end_link_pos = new_line_pos;
		}


		if (start_link_pos != NSNotFound && end_link_pos != NSNotFound)
		{
			link_counter++;
			NSString * linkURL = [body substringWithRange:NSMakeRange(start_link_pos, end_link_pos - start_link_pos)];

			// we need to ignore described links here, because they're already processed in another
			// method.. we can tell described links, because they will have a ")" when processed here
			if ([linkURL rangeOfString:@")" options:NSCaseInsensitiveSearch].location == NSNotFound)
			{
				NSMutableDictionary * link = [[NSMutableDictionary alloc] init];
				[link setValue:[comment valueForKey:@"comment_index"] forKey:@"comment_index"];
				[link setValue:[NSString stringWithString:linkURL] forKey:@"description"];
				[link setValue:[NSString stringWithString:linkURL] forKey:@"original_url"];
				[link setValue:[RedditAPI getLinkType:linkURL] forKey:@"type"];
				[link setValue:[RedditAPI fixImgurLink:linkURL] forKey:@"url"];
				[link setValue:@"NO" forKey:@"isDescribed"];
				[link setValue:[NSNumber numberWithInt:link_counter] forKey:@"linkTag"];
				[link setValue:[NSString stringWithFormat:@"%d",[allLinks count]] forKey:@"link_id"];
//				[link setValue:[[NSNumber alloc] initWithInt:link_counter] forKey:@"linkTag"];
//				[link setValue:[[NSString alloc] initWithFormat:@"%d",[allLinks count]] forKey:@"link_id"];
				[allLinks addObject:link];
				[links addObject:link];
			}
			pos = end_link_pos;
		}
		else
			linksAvailable = FALSE;
	}
	[body release];
	return links;
}

- (NSMutableArray *) parseBodyForDescribedLinks:(NSMutableDictionary *) comment
{
	NSMutableString * body = [[comment valueForKey:@"body"] copy];
//	NSMutableArray * links = [[NSMutableArray alloc] init];
	NSMutableArray * links = [NSMutableArray arrayWithCapacity:0];	
	int bodyLength = [body length];
	int pos = 0;
	// left square bracket position
	int lsqb = 0;
	int rsqb = 0;

	// left round bracket
	int lrb = 0;
	int rrb = 0;
	int link_counter = 0;
	BOOL linksAvailable = TRUE;
	
	while (linksAvailable) {
		lsqb = [body rangeOfString:@"[" options:NSCaseInsensitiveSearch range:NSMakeRange (pos, bodyLength - pos)].location + 1;
		rsqb = [body rangeOfString:@"](" options:NSCaseInsensitiveSearch range:NSMakeRange (lsqb, bodyLength - lsqb)].location;
		lrb = rsqb + 2;
		rrb = [body rangeOfString:@")" options:NSCaseInsensitiveSearch range:NSMakeRange (lrb, bodyLength - lrb)].location;
		if (lsqb != NSNotFound && rsqb != NSNotFound && rrb != NSNotFound)
		{
			link_counter++;
			NSString * linkName = [body substringWithRange:NSMakeRange(lsqb, rsqb - lsqb)];
			NSString * linkURL = [body substringWithRange:NSMakeRange(lrb, rrb - lrb)];
			NSMutableDictionary * link = [[NSMutableDictionary alloc] init];
			[link setValue:[comment valueForKey:@"comment_index"] forKey:@"comment_index"];
			[link setValue:[linkName copy] forKey:@"description"];
			[link setValue:[linkURL copy] forKey:@"original_url"];
			[link setValue:[RedditAPI getLinkType:linkURL] forKey:@"type"];
			[link setValue:[RedditAPI fixImgurLink:linkURL] forKey:@"url"];
			[link setValue:[[NSNumber alloc] initWithInt:link_counter] forKey:@"linkTag"];		

			// some links have a description that is the same as the URL
			// technically these are not described.
			if ([linkName isEqualToString:linkURL])
				[link setValue:@"NO" forKey:@"isDescribed"];				
			else
				[link setValue:@"YES" forKey:@"isDescribed"];

			[link setValue:[NSString stringWithFormat:@"%d",[allLinks count]] forKey:@"link_id"];
			[allLinks addObject:link];
		
			[links addObject:link];
//			[link release];
			[linkName release];
			[linkURL release];
			pos = rrb;
		}
		else
			linksAvailable = false;
	}
	[body release];	
	return links;
}

- (NSMutableArray *) processLinks:(NSMutableDictionary *) comment
{
	NSMutableArray * links = [self parseBodyForDescribedLinks:comment];
	
	// if the poster doesn't describe links with [...](http...) look for
	// undescribed links.
//	if ([links count] == 0)
		[links addObjectsFromArray:[self parseBodyForUndescribedLinks:comment]];
	
	return links;
}


- (NSMutableDictionary *) reformat:(NSMutableDictionary *) comment
{
	// add a newline so that comments that contain only links can be identified
	// as the end of a url is determined by a space or newline character.
	
	NSMutableString * body = [NSMutableString stringWithString:[comment valueForKey:@"body"]];
	[body appendString:@" "];
	[comment setValue:body forKey:@"body"];
	NSArray * links = [self processLinks:comment];

	for (NSDictionary * link in links)
	{
		NSString * linkstr;
		NSString * replacement;
		if ([[link valueForKey:@"isDescribed"] boolValue])
		{
			linkstr = [NSString stringWithFormat:@"[%@](%@)",[link valueForKey:@"description"], [link valueForKey:@"original_url"]];
			replacement = [NSString stringWithFormat:@"%@ [%d]",[link valueForKey:@"description"], [[link valueForKey:@"linkTag"] intValue]];

		} else
		{
			linkstr = [NSString stringWithFormat:@"%@",[link valueForKey:@"original_url"]];
			replacement = [NSString stringWithFormat:@"[%d]",[[link valueForKey:@"linkTag"] intValue]];
		}

		// remove the body entirely if all it contains is a link (as we'll be showing these as buttons):
		if (abs([linkstr length] - [body length]) < 5)
		{
			[body setString:@""];
		}
		else
		{
			[body replaceOccurrencesOfString:linkstr withString:replacement options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
		}
	}
	[body replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
	[body replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
	[body replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
	
	[comment setValue:body forKey:@"body"];
	[comment setValue:links forKey:@"links"];

	return comment;
}




// iterate through comments, and add them to the comments array
- (void) processCommentThread:(NSMutableDictionary *) comment withLevel: (int) level withParents: (NSString *) parents
{
	// on occassion, the Reddit API sends blank IDs for comments, and we need to ignore such comments
	// otherwise they will cause AlienBlue to crash.
	if(![comment valueForKey:@"id"])
		return;
	
	[comment setValue:[NSNumber numberWithInt:[comments count]] forKey:@"comment_index"];
	[comment setValue:[NSString	stringWithFormat:@"%d",level] forKey:@"level"];


	if ([[comment valueForKey:@"author"] isEqualToString:[post valueForKey:@"author"]])
		[comment setValue:@"op" forKey:@"comment_type"];
	else if ([[comment valueForKey:@"author"] isEqualToString:[redAPI authenticatedUser]])
		[comment setValue:@"me" forKey:@"comment_type"];
	else
		[comment setValue:@"normal" forKey:@"comment_type"];
	
	// initialise vote direction
	int voteDirection = 0;
	if(![[comment objectForKey:@"likes"] isKindOfClass:[NSNull class]] && [[comment valueForKey:@"likes"] boolValue])
		voteDirection = 1;
	else if(![[comment objectForKey:@"likes"] isKindOfClass:[NSNull class]] && ![[comment valueForKey:@"likes"] boolValue])
		voteDirection = -1;
	[comment setValue:[NSNumber numberWithInt:voteDirection] forKey:@"voteDirection"];
	
	// calculate score (for some reason, the live reddit.com server doesn't compute the score
	// for comments, so we do this manually:
	int ups = [[comment valueForKey:@"ups"] intValue];
	int downs = [[comment valueForKey:@"downs"] intValue];
	[comment setValue:[NSNumber numberWithInt:(ups - downs)] forKey:@"score"];
	
	
	comment = [self reformat:comment];

	[comments addObject:comment];
	
//	[parents appendString:@":"];
//	[parents appendString:[comment valueForKey:@"id"]];
	NSString * nParents = [[parents stringByAppendingString:@":"] stringByAppendingString:[comment valueForKey:@"id"]];
	
//	NSLog(nParents);
	[comment setValue:nParents forKey:@"parents"];
	int numReplies = 0;
	if (![[comment objectForKey:@"replies"] isKindOfClass:[NSString class]] )
	{
		NSArray * rawComments = [[[comment objectForKey:@"replies"] objectForKey:@"data"] objectForKey:@"children"];
		//		[comment setValue:[NSString stringWithFormat:@"%d",[rawComments count]] forKey:@"numReplies"];
		for (NSDictionary * rawComment in rawComments ) 
		{ 
			// exclude the "more..." threads
			if (![[rawComment valueForKey:@"kind"] isEqualToString:@"more"])
			{
				[self processCommentThread:[rawComment objectForKey:@"data"] withLevel:level+1 withParents:nParents];
				numReplies ++;
			}
		}	
	}
	[comment setValue:[NSString stringWithFormat:@"%d",numReplies] forKey:@"numReplies"];
}

- (void) processComments:(NSMutableDictionary *) data
{
	NSArray * rawComments = [[data objectForKey:@"data"] objectForKey:@"children"];
	for (NSMutableDictionary * rawComment in rawComments ) 
	{ 
		if (![[rawComment valueForKey:@"kind"] isEqualToString:@"more"])		
			[self processCommentThread:[rawComment objectForKey:@"data"] withLevel:0 withParents:@""];
	}
}



- (IBAction)apiCommentsResponse:(id)sender
{

	NSLog(@"-- apiCommentsResponse in()");
	stime = CFAbsoluteTimeGetCurrent();
	
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];		
	NSMutableDictionary *comment_data = [sender objectAtIndex:1];

	post = [NSMutableDictionary dictionaryWithDictionary:[[[[[sender objectAtIndex:0] objectForKey:@"data"] objectForKey:@"children"] objectAtIndex:0] objectForKey:@"data"]];
	
	NSMutableString * post_body = [NSMutableString stringWithString:@""];
	
	if ([RedditAPI isImageLink:[post valueForKey:@"url"]])
	{
		[post_body setString:[post valueForKey:@"url"]];
//		post_body = [[post valueForKey:@"url"] copy];
	} else if ([post objectForKey:@"selftext"] && [[post objectForKey:@"selftext"] length])
	{
		[post_body setString:[post valueForKey:@"selftext"]];		
//		post_body = [[post valueForKey:@"selftext"] copy];
	}
	
	[post setValue:post_body forKey:@"body"];
	[self processCommentThread:post withLevel:0 withParents:@""];
	
	[self processComments:comment_data];
	
	NSLog(@"-- comment list response --");
	
	// we go above the [comments count] to take into account the post info
	// cell in the  first row
	for (int i=0; i<([comments count] + 1); i++)
		[bodyHeightCache addObject:[NSNumber numberWithFloat:-1]];

	selected_row = -1;
	editing_row = -1;
	
//	filteredListContent = [[NSMutableArray alloc] init];

	NSLog(@"Imported Comments : [%d]", [comments count]);

	[[self tableView] reloadData];
	[self completeProgressBar];

	etime = CFAbsoluteTimeGetCurrent();
	
	NSLog(@"time to import comments : %f", etime - stime);

	if ([RedditAPI isImageLink:[post valueForKey:@"url"]])
	{
		// the following automatically loads the inline image to give
		// context to the comments
//		UIButton * button = [[UIButton alloc] init];
//		[button setTag:0];
//		NSLog(@"--image url is : %@", [post valueForKey:@"url"]);
//		[self linkClicked:button];
	}	

	[Resources processPost:post];
	
//	[[nc post] release];
	[nc setPost:post];
	[nc refreshVotingSegment];
	


	
	if ([nc replyCommentID] && [[nc replyCommentID] length] > 0)
	{
//		NSLog(@"[*] scrolling to comment with id:%@", [nc replyCommentID]);
		int replyRow = [self getCommentRowByName:[nc replyCommentID]];
//		NSLog(@"[*] scrolling to row : %d", replyRow);
		[self scrollToRow:replyRow];
		[nc setReplyCommentID:nil];
	}
	
//	[self scrollToRow:52];	
//	[self testTableDrawPerformanceStart];
//	[comment_data release];
}

- (void) loadTestComments
{
	if (progressTimer)
		progressTimer = nil;
	
	[self enableProgressBar];
	[comments release];
	[allLinks release];
	[bodyHeightCache release];
	comments = [[NSMutableArray alloc] init];
	allLinks = [[NSMutableArray alloc] init];
	bodyHeightCache = [[NSMutableArray alloc] init];
	
	
//	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	
	SBJSON *parser = [[SBJSON alloc] init];
	
	NSString *jsonfile = [[NSBundle mainBundle] pathForResource:@"mitch" ofType:@"json"];
	
	NSString *json_string = [[NSString alloc] initWithContentsOfFile:jsonfile];
	NSMutableDictionary *data = [[parser objectWithString:json_string error:nil] objectAtIndex:1];	
	[self apiCommentsResponse:data];
}


- (void) resetMemory
{
//	if (comments)
//	{
//		for (NSMutableDictionary * comment in comments)
//		{
//			NSMutableArray * links = (NSMutableArray *) [comment objectForKey:@"links"];
//			if (links)
//			{
//				for (NSDictionary * link in links)
//					[link release];
//			}
//		}
//	}
	for (NSMutableDictionary * link in allLinks)
		[link release];
	
	[comments release];
	[allLinks release];
	[bodyHeightCache release];	
}

- (void) loadComments
{
	if (progressTimer)
		progressTimer = nil;

	[self enableProgressBar];
	
	[self resetMemory];
	

	comments = [[NSMutableArray alloc] init];
	allLinks = [[NSMutableArray alloc] init];
	bodyHeightCache = [[NSMutableArray alloc] init];
		
	
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//	NSString * post_id = [nc postId];
	NSString * post_id = [[nc post] objectForKey:@"id"];
	
	NSLog(@"loading comments for post with id [%@]",post_id);
	
//	RedditAPI * redAPI = [(NeuRedditAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];	
	[redAPI fetchCommentsForPostID:post_id callBackTarget:self];
	[[self tableView] reloadData];
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void) loadAllImages
{
	if (![MKStoreManager isProUpgraded])
	{
		NSString *message = [[NSString alloc] initWithFormat: @"This feature allows you to view all images in a thread with a single tap.  You can upgrade to the PRO version in the \"Settings\" panel."];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Show All Images\n(PRO Feature)"
														message:message
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];		
		return;
	}
	
	NSString *message = [[NSString alloc] initWithFormat: @"Loading of all linked images can use a significant amount of Internet data.  Are you sure you want to continue?"];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Show all images"
													message:message
												   delegate:self
										  cancelButtonTitle:@"No"
										  otherButtonTitles:@"Yes",nil];
	[alert setTag:3];
	[alert show];
	[alert release];		
}

- (void)viewDidLoad {
    [super viewDidLoad];

	prefs = [NSUserDefaults standardUserDefaults];	
	redAPI = [(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];		
	
	if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        self.savedSearchTerm = nil;
    }	

//	voteUpIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vote-up" ofType:@"png"]];
//	voteDownIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vote-down" ofType:@"png"]];
//	voteUpSelectedIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vote-up-selected" ofType:@"png"]];
//	voteDownSelectedIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"vote-down-selected" ofType:@"png"]];

	UIImage * extraOptionsIcon = [[UIImage imageNamed:@"more-options-icon.png"] retain];			
	UIBarButtonItem *extraOptionsBarItem = [[[UIBarButtonItem alloc] initWithImage:extraOptionsIcon style:UIBarButtonItemStyleBordered target:self action:@selector(popupExtraOptionsActionSheet:)] autorelease];	
	self.navigationItem.rightBarButtonItem = extraOptionsBarItem;
	
	
//	[self loadTestComments];	
	
	NSLog(@"loaded");
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	NSLog(@"appeared");

	// refresh look of visible rows (e.g. if we come back after change to night-mode)
	[[self tableView] reloadRowsAtIndexPaths:[[self tableView] indexPathsForVisibleRows] withRowAnimation:NO];	
	
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//	self.navigationItem.titleView = [nc createVotingSegmentForView:self];
	if ([nc shouldRefreshComments])
	{
		[nc setShouldRefreshComments:FALSE];
		NSIndexPath * ind = [NSIndexPath indexPathForRow:0 inSection:0];
		[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionTop animated:NO];
		[self loadComments];
	}

	[[self tableView] setScrollsToTop:[[prefs valueForKey:@"allow_status_bar_scroll"] boolValue]];	
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/

- (void)viewDidDisappear:(BOOL)animated {
    // save the state of the search UI so that it can be restored if the view is re-created
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
	[super viewDidDisappear:animated];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	NSLog(@"comments rotated");
	[[self tableView] reloadRowsAtIndexPaths:[[self tableView] indexPathsForVisibleRows] withRowAnimation:NO];
}

//
//// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    // Return YES for supported orientations
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}
//

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	NSLog(@"memory warning received in CommentsTableController");
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
	if (!comments || [comments count] == 0)
	{
		return 1;
	}
	
    return [comments count];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"connection:didReceiveResponse in()");
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * imageDL = [linkImageDownloadQueue objectForKey:connectionKey];
	NSMutableData *imageData = [[NSMutableData alloc] init];
	[imageDL setValue:imageData	forKey:@"imageData"];
	
//	MovieDownload *md = [downloadQ valueForKey:connectionKey];
//	NSMutableData *fdata = [NSMutableData dataWithData:[md getData]];
//	[fdata setLength:0];
//	[md setData:fdata];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//	NSLog(@"connection:didReceiveData in()"); 	
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * imageDL = [linkImageDownloadQueue objectForKey:connectionKey];
	NSMutableData * imageData = (NSMutableData *) [imageDL objectForKey:@"imageData"];
	[imageData appendData:data];
//	NSLog(@"Data Length : %d", [imageData length]);
//	[imageDL setValue:imageData	forKey:@"imageData"];

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"connection:DidFailWithError in()"); 		
//    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"connection:DidFinishLoading in()");
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * imageDL = [linkImageDownloadQueue objectForKey:connectionKey];
	NSMutableDictionary * link = [imageDL objectForKey:@"link"];
	NSData * imageData = [imageDL objectForKey:@"imageData"];
	UIImage * image = [UIImage imageWithData:imageData];
	[link setValue:image forKey:@"image"];
	int row = [[imageDL valueForKey:@"comment_row"] intValue];

	// this handles an exception that occurs when comment_row is corrupted
	// and we get an out of bounds error on the following line
	if (row <0 || row > [comments count])
		return;
		
	NSDictionary * comment = [comments objectAtIndex:row];	
//	NSDictionary * comment = [comments objectAtIndex:row - 1];

	// we set this at the comment level, so that heightforrow() will know to fetch
	// the comment cell and render it to determine the row height.
	[comment setValue:@"YES" forKey:@"openedImage"];

	NSLog(@"-- updating row after download: %d --", row);	
	
	NSIndexPath * np = [NSIndexPath indexPathForRow:row inSection:0];
	CommentCell * cell = (CommentCell *) [self tableView:[self tableView] cellForRowAtIndexPath:np];
	// the drawLinkButtons call is required here, because only after drawing the images
	// can we determine a suitable row height
	[[cell commentCellView] drawLinkButtons];
	
	// reset the height cache for this row so that it is forced to recalculate
	// taking the image height into consideration.
	[self clearHeightCacheForRow:row];
	[self refreshRow:row];
	[linkImageDownloadQueue removeObjectForKey:connectionKey];

	// loading images inline sometimes corrupts the status bar and tab bar controller
	// in SDK 3.0.  So we redraw these frames just in case.
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[nc redrawFrames];

	[imageDL release];
}



- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
	NSLog(@"connection request");	
    return request;
}




- (void) addLinkImageToDownloadQueue:(NSMutableDictionary *) imageForQueue
{
	NSLog(@"add link to image download queue in()");
	if (!linkImageDownloadQueue)
	{
		NSLog(@"initialising download queue");
		linkImageDownloadQueue = [[NSMutableDictionary alloc] init];
	}
	[linkImageDownloadQueue setValue:imageForQueue forKey:[imageForQueue valueForKey:@"connectionKey"]];

}

- (void) loadImageInline:(NSMutableDictionary *) link
{
	NSString * url = [[link valueForKey:@"url"] copy];	
	[link setValue:@"Loading..." forKey:@"description"];
	int row = [[link valueForKey:@"comment_index"] intValue];
	NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:url]];	
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary *imageDL = [[NSMutableDictionary alloc] init];
	[imageDL setValue:connectionKey forKey:@"connectionKey"];
	[imageDL setValue:link forKey:@"link"];
	[imageDL setValue:[NSString stringWithFormat: @"%d",[link valueForKey:@"link_id"]] forKey:@"link_id"];
	[imageDL setValue:[NSString stringWithFormat: @"%d",row] forKey:@"comment_row"];
	[self addLinkImageToDownloadQueue:imageDL];
	[self refreshRow:row];		
}

- (IBAction)linkClicked:(id)sender {
	NSLog(@"link Clicked in()");
	UIButton * button = (UIButton *) sender;
	NSMutableDictionary * link = [allLinks objectAtIndex:[button tag]];
//	int row = [[button superview] tag] + 1;
	int row = [[[[button superview] superview] superview] tag];
	NSString * url = [[link valueForKey:@"url"] copy];
	NSLog(@"-- downloading [%@] -- in row [%d]", url, row);
	if ([[link valueForKey:@"type"] isEqualToString:@"image"])
	{
		[self loadImageInline:link];
	}
	else
		[self moreButtonClicked:sender];
	
	
//	if ([[link valueForKey:@"type"] isEqualToString:@"image"])
//	{
//		NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:[link valueForKey:@"url"]]];
//		UIImage* image = [[UIImage alloc] initWithData:imageData];
//		[link setValue:image forKey:@"image"];
//		int row = [[button superview] tag];
//		// reset the height cache for this row so that it is forced to recalculate
//		// taking the image height into consideration.
//		[bodyHeightCache replaceObjectAtIndex:row withObject:@"-1"];
//		
//		NSMutableArray * affectedRows = [[NSMutableArray alloc] init];
//		NSIndexPath * ind = [NSIndexPath indexPathForRow:row inSection:0];
//		[affectedRows addObject:ind];
//		[[self tableView] reloadRowsAtIndexPaths:affectedRows withRowAnimation:UITableViewRowAnimationNone];
//		[affectedRows release];
//	}
}

- (IBAction)moreButtonClicked:(id)sender {
	UIButton * button = (UIButton *) sender;
	NSDictionary * link = [allLinks objectAtIndex:[button tag]];
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[nc browseToLinkFromComment:[link valueForKey:@"url"]];
}


- (UITableViewCell *) createProgressCell
{
	UITableViewCell * progressCell = [[[UITableViewCell alloc] init] autorelease];
	[progressCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	UIProgressView * progress = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
	CGRect progressFrame = CGRectMake(40, 25, 240, 40);
	
	[progress setFrame:progressFrame];
	
	// hide the progress bar when it isn't in use.
	if (CommentsLoadProgressValue > 0.0 && CommentsLoadProgressValue < 1.0)
	{
		[progress setHidden:NO];	
		[progress setProgress:CommentsLoadProgressValue];
	}
	else
	{
		[progress setHidden:NO];
	}
	[progress setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];	
	[progressCell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[progressCell addSubview:progress];	
	return progressCell;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

//	NSLog(@"cellForRowAtIndexPath requested for cell [%d]", indexPath.row);
	
	if ([comments count] == 0  && indexPath.row == 0)
		return [self createProgressCell];
	
	NSMutableDictionary *comment;
	
	int comment_row = indexPath.row;
    comment = [comments objectAtIndex:comment_row];

	NSString * CellIdentifier = @"FastCommentCell";

	CommentCell *cell = (CommentCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[CommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.frame = CGRectMake(0.0, 0.0, 320.0, 100);
	}
	
	[cell setTag:comment_row];

	CommentWrapper * wrapper = [[CommentWrapper alloc] initWithComment:comment forController:self];
	[cell setCommentWrapper:wrapper];
	[wrapper release];

    return cell;
}

- (IBAction)cancelReplyPressed:(id)sender {
	NSLog(@"cancelReplyPressed in()");
	UIButton *button = (UIButton *)sender;	
	NSDictionary * comment = [comments objectAtIndex:[button tag]];
	[comment setValue:@"NO" forKey:@"showReplyArea"];
//	[comment setValue:@"NO" forKey:@"showOptions"];
//	[self refreshRow:[button tag] + 1];
	[self refreshRow:[button tag]];	
}

- (void)editModeForComment:(NSMutableDictionary *) comment {
	NSLog(@"editModeForComment in()");
	if (![redAPI authenticated])
	{
		[redAPI showAuthorisationRequiredDialog];
		return;
	}
	[comment setValue:@"YES" forKey:@"showReplyArea"];
	[comment setValue:@"NO" forKey:@"showOptions"];
	[comment setValue:@"YES" forKey:@"editMode"];
	[comment setValue:[comment valueForKey:@"body"] forKey:@"replyText"];
	[self refreshRow:[[comment valueForKey:@"comment_index"] intValue]];	
}

//- (IBAction)editPressed:(id)sender {
//	NSLog(@"editPressed in()");
//	if (![redAPI authenticated])
//	{
//		[redAPI showAuthorisationRequiredDialog];
//		return;
//	}
//	UIButton *button = (UIButton *)sender;	
//	NSDictionary * comment = [comments objectAtIndex:[button tag]];
//	[comment setValue:@"YES" forKey:@"showReplyArea"];
//	[comment setValue:@"NO" forKey:@"showOptions"];
//	CommentCell * cell = (CommentCell *) [[[button superview] superview] superview];
//	[comment setValue:@"YES" forKey:@"editMode"];
//	[comment setValue:[comment valueForKey:@"body"] forKey:@"replyText"];
////	[[cell submitReply] setTitle:@"Update" forState:UIControlStateNormal];
//	//	[self refreshRow:[button tag] + 1];
//	[self refreshRow:[button tag]];	
//}


//- (void)cancelReplyForComment:(NSMutableDictionary *) comment {
//	NSLog(@"cancelReplyPressed in()");
//	[comment setValue:@"NO" forKey:@"showReplyArea"];
//	[self refreshRow:[[comment valueForKey:@"comment_index"] intValue]];
//}

- (void)showReplyAreaForComment:(NSMutableDictionary *) comment {
	NSLog(@"showReplyAreaPressed in()");
	if (![redAPI authenticated])
	{
		[redAPI showAuthorisationRequiredDialog];
		return;
	}
	[comment setValue:@"normal" forKey:@"visibility"];
	[comment setValue:@"YES" forKey:@"showReplyArea"];
	[comment setValue:@"NO" forKey:@"showOptions"];
	[self refreshRow:[[comment valueForKey:@"comment_index"] intValue]];
}



//- (IBAction)showReplyAreaPressed:(id)sender {
//	NSLog(@"showReplyAreaPressed in()");
//	if (![redAPI authenticated])
//	{
//		[redAPI showAuthorisationRequiredDialog];
//		return;
//	}
//	UIButton *button = (UIButton *)sender;	
//	NSDictionary * comment = [comments objectAtIndex:[button tag]];
//	[comment setValue:@"YES" forKey:@"showReplyArea"];
//	[comment setValue:@"NO" forKey:@"showOptions"];
////	[self refreshRow:[button tag] + 1];
//	[self refreshRow:[button tag]];	
//}

- (IBAction)gotoParent:(id)sender {
	NSLog(@"goto parent in()");
	UIButton *button = (UIButton *)sender;
	NSDictionary * comment = [comments objectAtIndex:[button tag]];
	NSDictionary * parent = [self getCommentById:[comment valueForKey:@"parent_id"]];
	[self scrollToRow:[[parent valueForKey:@"comment_index"] intValue]];
//	if (parent != nil && [[parent valueForKey:@"body"] length] > 5)
//	{
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"In response to:" message:[parent valueForKey:@"body"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//		[alert show];
//		[alert release];		
//	}
	
}


- (void)contextForComment:(NSMutableDictionary *) comment {
	NSLog(@"comment parent in()");
	NSDictionary * parent = [self getCommentById:[comment valueForKey:@"parent_id"]];
	if (parent != nil && [[parent valueForKey:@"body"] length] > 5)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"In response to:" message:[parent valueForKey:@"body"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];		
	}
}

- (void) toggleSavePost:(NSMutableDictionary *) ps {
	if ([[ps valueForKey:@"saved"] boolValue])
	{
		[redAPI unsavePostWithID:[ps valueForKey:@"name"]];
		[ps setValue:[NSNumber numberWithBool:NO] forKey:@"saved"];
	}
	else
	{
		[redAPI savePostWithID:[post valueForKey:@"name"]];
		[ps setValue:[NSNumber numberWithBool:YES] forKey:@"saved"];
	}
	[self refreshRow:0];
}

- (void) toggleHidePost:(NSMutableDictionary *) ps {
	if ([[ps valueForKey:@"hidden"] boolValue])
	{
		[redAPI unhidePostWithID:[ps valueForKey:@"name"]];
		[ps setValue:[NSNumber numberWithBool:NO] forKey:@"hidden"];
	}
	else
	{
//		NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//		PostsTableControllerView * ptcv = (PostsTableControllerView *) [[[nc postsNavigation] viewControllers] objectAtIndex:0];
//		[ptcv hideSinglePost:[nc post]];
		[redAPI hidePostWithID:[ps valueForKey:@"name"]];
		[ps setValue:[NSNumber numberWithBool:YES] forKey:@"hidden"];
	}
	[self refreshRow:0];
}

- (void) voteUpComment:(NSMutableDictionary *) comment {
	NSLog(@"voteUpPressed in()");
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[nc upvoteItem:comment];
	[self refreshRow:[[comment valueForKey:@"comment_index"] intValue]];
}

- (void) voteDownComment:(NSMutableDictionary *) comment {
	NSLog(@"voteDownPressed in()");
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[nc downvoteItem:comment];
	[self refreshRow:[[comment valueForKey:@"comment_index"] intValue]];
}


//- (IBAction)voteUpPressed:(id)sender {
//	NSLog(@"voteUpPressed in()");
//	UIButton *button = (UIButton *)sender;	
//	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//	NSMutableDictionary * comment = [comments objectAtIndex:[button tag]];
//	[nc upvoteItem:comment];
//	[self refreshRow:[button tag]];
//
//}

- (IBAction)loginResponse:(id)sender {
	NSLog(@"comments :: loginResponse()");
	NSString * modhash = (NSString *) sender;
	NSLog(modhash);
}

//- (IBAction)voteDownPressed:(id)sender {
//	NSLog(@"voteDownPressed in()");
//	UIButton *button = (UIButton *)sender;		
//	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
//	NSMutableDictionary * comment = [comments objectAtIndex:[button tag]];	
//	[nc downvoteItem:comment];
//	[self refreshRow:[button tag]];	
////	RedditAPI * redAPI = [(NeuRedditAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];
////	[redAPI loginUser:@"apitest9" withPassword:@"test9" callBackTarget:self];
//
//}

- (IBAction)submitReplyPressed:(id)sender {
	NSLog(@"submitReplyPressed in()");
	UIButton *button = (UIButton *)sender;	
	NSMutableDictionary * comment = [comments objectAtIndex:[button tag]];
	
	CommentCellView * ccv = (CommentCellView *) [button superview];
	[comment setValue:[[ccv replyTextView] text] forKey:@"replyText"];
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	NSLog([comment valueForKey:@"replyText"]);
	[nc replyToItem:comment];
	[comment setValue:@"NO" forKey:@"showReplyArea"];
	[self refreshRow:[button tag]];	
}

- (void) afterCommentReply:(NSString *) commentID
{
	NSLog(@"reload and scroll in");
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[nc setReplyCommentID:commentID];
	[self loadComments];
}

- (int) getCommentRowByName:(NSString *) cname
{
	int row_counter = 0;
	for(NSDictionary * comment in comments)
	{
		if([cname isEqualToString:[comment valueForKey:@"name"]])
			return row_counter;
		row_counter++;
	}
	return 0;
}


- (NSMutableDictionary *) getCommentById:(NSString *) cId
{
	for(NSMutableDictionary * comment in comments)
	{
		NSRange range = [cId rangeOfString : [comment valueForKey:@"id"]];
		if (range.location != NSNotFound) {
			return comment;			
		}
	}
	return nil;
}

- (NSMutableArray *) makeArrayUnique:(NSMutableArray *) mutableArray
{
	NSArray *copy = [mutableArray copy];
	NSInteger index = [copy count] - 1;
	for (id object in [copy reverseObjectEnumerator]) {
		if ([mutableArray indexOfObject:object inRange:NSMakeRange(0, index)] != NSNotFound) {
			[mutableArray removeObjectAtIndex:index];
		}
		index--;
	}
	[copy release];
	return mutableArray;
}


// this returns the comment as well as sub-comments
- (NSArray *) allChildrenForComment:(NSDictionary *) comment
{
	NSMutableArray * children = [[NSMutableArray alloc] init];
	int comment_level = [[comment valueForKey:@"level"] intValue];
	NSString * comment_id = [comment valueForKey:@"id"];
	NSLog(@"finding children for comment:");
	NSLog(comment_id);
	for(NSDictionary * cmt in comments)
	{
		NSRange range = [[cmt valueForKey:@"parents"] rangeOfString : comment_id];
		if (range.location != NSNotFound) {
			NSArray *chain = [[cmt valueForKey:@"parents"] componentsSeparatedByString: @":"];
			for (int i=comment_level + 1; i<[chain count]; i++)
			{
				[children addObject:[self getCommentById:[chain objectAtIndex:i]]];
			}
		}
	}
	children = [self makeArrayUnique:children];
	return children;
}

- (void) showHideComments:(NSArray *) thread doHide:(BOOL) hide
{
	NSMutableArray * affectedRows = [[NSMutableArray alloc] init];
	int counter = 0;
	for (NSDictionary * comment in thread)
	{
		NSIndexPath * ind = [NSIndexPath indexPathForRow:([[comment valueForKey:@"comment_index"] intValue]) inSection:0];

		// TODO :: Must find out why there is a stream of:
		// -- mark for update row: 0 (everytime a row is collapsed or opened

		//NSLog(@" -- mark for update row: %d",[[comment valueForKey:@"cellRow"] intValue] );
		// handle the duplicates coming in on row:0
//		if (ind.row != 0)
			[affectedRows addObject:ind];

		if ([comment valueForKey:@"visibility"])
			[[comment valueForKey:@"visibility"] release];

		if (hide)
		{
			[comment setValue:@"hidden" forKey:@"visibility"];
			if (counter++ == 0)
				[comment setValue:@"collapsed" forKey:@"visibility"];
		}
		else
		{
			[comment setValue:@"normal" forKey:@"visibility"];
		}
	}
	[[self tableView] reloadRowsAtIndexPaths:[self makeArrayUnique:affectedRows] withRowAnimation:UITableViewRowAnimationFade];
	[affectedRows release];

}

- (void) collapseToRootForComment:(NSMutableDictionary *) comment {
	NSLog(@"collapsing comment to root");
	NSLog(@"parents :: %@", [comment valueForKey:@"parents"]);
	NSArray *chain = [[comment valueForKey:@"parents"] componentsSeparatedByString: @":"];
	if (chain && [chain count] > 0)
	{
		NSString * rootId = [chain objectAtIndex:1];
		NSLog(@"root parent :: %@", rootId);
		NSMutableDictionary * rootComment = [self getCommentById:rootId];
		
		// this check is to make sure that we only toggle for collapsing, not
		// expanding here.
		if (![[rootComment valueForKey:@"visibility"] isEqualToString:@"collapsed"])
		{
			// scroll up to the root comment first so that we don't disorient the
			// user.
			NSIndexPath * scrRow = [NSIndexPath indexPathForRow:[[rootComment valueForKey:@"comment_index"] intValue] inSection:0];
			CGRect rect = [[self tableView] rectForRowAtIndexPath:scrRow];
			[[self tableView] scrollRectToVisible:rect animated:YES];			
			
			[self toggleComment:rootComment];
		}
	}
}

- (void) toggleComment:(NSMutableDictionary *) comment {
	
	NSLog(@"toggling comment : %d", [[comment valueForKey:@"comment_index"] intValue]);
	
	NSArray * thread = [self allChildrenForComment:comment];
	if ([[comment valueForKey:@"visibility"] isEqualToString:@"collapsed"] ||
		[[comment valueForKey:@"visibility"] isEqualToString:@"hidden"])
		[self showHideComments:thread doHide:FALSE];
	else
		[self showHideComments:thread doHide:TRUE];	

	// if user toggles the last comment, scroll so that the user can see that the message
	// has opened.
	if ([[comment valueForKey:@"comment_index"] intValue] == ([comments count] - 1))
	{
		NSLog(@"last comment toggled");
		[self scrollToRow:[[comment valueForKey:@"comment_index"] intValue]];
	}
	[thread release];
}


//- (IBAction)toggleComment:(id)sender {
//	NSLog(@"toggleComment in()");
//	UIButton *button = (UIButton *)sender;
//	NSDictionary * comment = [comments objectAtIndex:[button tag]];
//	NSArray * thread = [self allChildrenForComment:comment];
//	if ([[comment valueForKey:@"visibility"] isEqualToString:@"collapsed"] ||
//		[[comment valueForKey:@"visibility"] isEqualToString:@"hidden"])
//		[self showHideComments:thread doHide:FALSE];
//	else
//		[self showHideComments:thread doHide:TRUE];		
//	
//}

- (IBAction)showContext:(id)sender {
//	UIButton *button = (UIButton *)sender;
//	NSDictionary * comment = [comments objectAtIndex:[button tag]];
//	NSDictionary * parent = [self getCommentById:[comment valueForKey:@"parent_id"]];
//	
//	if (parent != nil)
//	{
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"In response to:" message:[parent valueForKey:@"body"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//		[alert show];
//		[alert release];		
//	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//	NSLog(@"-- cell height requested for row [%d]", indexPath.row);	
	
	if (!comments || [comments count] == 0)
		return 150;

	float header_height = 50;
	float bottom_padding = 90;
	float comment_options_height = 50; 
	float comment_reply_area = 135;

	NSDictionary * comment = [comments objectAtIndex:indexPath.row];
//	NSDictionary * comment = [comments objectAtIndex:indexPath.row - 1];

	if ([[comment valueForKey:@"visibility"] isEqualToString:@"collapsed"])
		return header_height;
	else if ([[comment valueForKey:@"visibility"] isEqualToString:@"hidden"])
		return 0;

	float cs = [[bodyHeightCache objectAtIndex:indexPath.row] floatValue];	

	// there is no valid cached value - so we must recalculate
	if (cs < 0)
	{
		cs = 0;
		UIFont *cellFont = [Resources mainFont];
		
		// posts row has a variable title-height that we need to estimate
		if (indexPath.row == 0)
		{
			CGSize constraintSize = CGSizeMake([tableView frame].size.width - 30.0, MAXFLOAT);
			CGSize labelSize = [[comment valueForKey:@"title"] sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
			cs += labelSize.height + 60;
			// the 40 takes into account the post creation date displayed
		}	
	
		
		// guestimate the height of the body text
		CGSize constraintSize;
		constraintSize = CGSizeMake([tableView frame].size.width - 45.0, MAXFLOAT);
		CGSize labelSize = [[comment valueForKey:@"body"] sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
		cs += labelSize.height + 20;
		
		if ([comment objectForKey:@"openedImage"])
		{
			NSLog(@"-- need to render height due to opened image -- for row : %d", indexPath.row);
			for (NSDictionary * link in [comment objectForKey:@"links"])
			{
				if ([link objectForKey:@"linkHeight"])
				{
					cs += [[link valueForKey:@"linkHeight"] floatValue] + 10;
				}
				else
				{
					cs += 20;
				}
			}
		}
		else 
		{
			// otherwise, take a good guess at the height because it doesn't contain open images,
			//and is a lot faster than rendering the cell first.
			cs += ([[comment objectForKey:@"links"] count] * 50);
		}
		
		[bodyHeightCache replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithFloat:cs]];
	}

	if ([comment objectForKey:@"showReplyArea"] && [[comment valueForKey:@"showReplyArea"] boolValue])	
	{
		cs += comment_reply_area;
	}	
	
	if ([comment objectForKey:@"showOptions"] && [[comment valueForKey:@"showOptions"] boolValue])
	{
		cs += comment_options_height;
	}

	cs += bottom_padding;	
	
	return cs;
}

- (void) selectComment:(NSMutableDictionary *) comment {
	
	NSIndexPath * scrollRow = nil;
	// user tapped on the loading progress bar
	if (!comments || [comments count] == 0)
		return;
	
	NSMutableArray * affectedRows = [[NSMutableArray alloc] init];		
	//	NSDictionary * comment = [comments objectAtIndex:indexPath.row - 1];
	
	// clicking on the same row twice hides the edit view	
	if ([comment objectForKey:@"showOptions"] && [[comment valueForKey:@"showOptions"] boolValue])
	{
		[comment setValue:@"NO" forKey:@"showOptions"];
		NSIndexPath * rowPath = [NSIndexPath indexPathForRow:editing_row inSection:0];	
		[affectedRows addObject:rowPath];
		[self clearHeightCacheForRow:rowPath.row];
		editing_row = -1;
	}
	// if the reply area is showing, don't render the comment options.  The user should first
	// cancel the reply (or submit it).
	else if ([comment objectForKey:@"showReplyArea"] && [[comment valueForKey:@"showReplyArea"] boolValue])
	{
	}
	else
	{
		// deselect previously selected rows.
		if (editing_row > -1)
		{
			NSDictionary * previouslySelectedComment = [comments objectAtIndex:editing_row];			
			[previouslySelectedComment setValue:@"NO" forKey:@"showOptions"];
			NSIndexPath * previousRowPath = [NSIndexPath indexPathForRow:editing_row inSection:0];	
			[affectedRows addObject:previousRowPath];
			[self clearHeightCacheForRow:previousRowPath.row];
		}
		[comment setValue:@"YES" forKey:@"showOptions"];
		editing_row = [[comment valueForKey:@"comment_index"] intValue];
		NSIndexPath * rowPath = [NSIndexPath indexPathForRow:editing_row inSection:0];	
		scrollRow = rowPath;
		
		[affectedRows addObject:rowPath];
		[self clearHeightCacheForRow:rowPath.row];
	}
	
	[[self tableView] reloadRowsAtIndexPaths:[self makeArrayUnique:affectedRows] withRowAnimation:UITableViewRowAnimationNone];		
	[affectedRows release];
	
	
	if (scrollRow)
	{
		if (scrollRow.row == [comments count] - 1)
		{
			[[self tableView] scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		}
		else
		{
			// find the co-ordinates of the row *after* the one we want to scroll to
			// and work our way back up about 90 pixels to make sure that the 
			// comment options are visible.
			NSIndexPath * nextRow = [NSIndexPath indexPathForRow:scrollRow.row + 1 inSection:0];
			CGRect rect = [[self tableView] rectForRowAtIndexPath:nextRow];

			// This used to align the bottom of the comment options with the bottom
			// of the view panel.  However, I have found that this causes frustration as
			// the user may end up clicking on the "Posts / Messages / Settings" options
			// by accident.
			//rect.origin.y = rect.origin.y - 90;

			rect.origin.y = rect.origin.y - 30;			
			rect.size.height = 60;
			[[self tableView] scrollRectToVisible:rect animated:YES];
		}
	}
	
	NSLog(@"Selected Row (from body click) %d", [[comment valueForKey:@"comment_index"] intValue]);
	//	[affectedRows release];
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//	NSIndexPath * scrollRow = nil;
//	// user tapped on the loading progress bar
//	if (!comments || [comments count] == 0)
//		return;
//
//	// user tapped on the post information
////	if (indexPath.row == 0)
////		return;
//	
//	NSMutableArray * affectedRows = [[NSMutableArray alloc] init];		
//	NSDictionary * comment = [comments objectAtIndex:indexPath.row];
//	//	NSDictionary * comment = [comments objectAtIndex:indexPath.row - 1];
//
//	// clicking on the same row twice hides the edit view	
//	if ([comment objectForKey:@"showOptions"] && [[comment valueForKey:@"showOptions"] boolValue])
//	{
//		[comment setValue:@"NO" forKey:@"showOptions"];
//		NSIndexPath * rowPath = [NSIndexPath indexPathForRow:editing_row inSection:0];	
//		[affectedRows addObject:rowPath];
//		[self clearHeightCacheForRow:rowPath.row];
//		editing_row = -1;
//	}
//	// if the reply area is showing, don't render the comment options.  The user should first
//	// cancel the reply (or submit it).
//	else if ([comment objectForKey:@"showReplyArea"] && [[comment valueForKey:@"showReplyArea"] boolValue])
//	{
//	}
//	else
//	{
//		// deselect previously selected rows.
//		if (editing_row > -1)
//		{
//			NSDictionary * previouslySelectedComment = [comments objectAtIndex:editing_row];			
//			[previouslySelectedComment setValue:@"NO" forKey:@"showOptions"];
//			NSIndexPath * previousRowPath = [NSIndexPath indexPathForRow:editing_row inSection:0];	
//			[affectedRows addObject:previousRowPath];
//			[self clearHeightCacheForRow:previousRowPath.row];
//		}
//		[comment setValue:@"YES" forKey:@"showOptions"];
//		editing_row = indexPath.row;
//		NSIndexPath * rowPath = [NSIndexPath indexPathForRow:editing_row inSection:0];	
//		scrollRow = rowPath;
//
//		[affectedRows addObject:rowPath];
//		[self clearHeightCacheForRow:rowPath.row];
//	}
//
//	[tableView reloadRowsAtIndexPaths:[self makeArrayUnique:affectedRows] withRowAnimation:UITableViewRowAnimationNone];		
//	[affectedRows release];
//	
//	if (scrollRow)
//	{
//		if (scrollRow.row == [comments count] - 1)
//		{
//			[tableView scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//		}
//		else
//		{
//			// find the co-ordinates of the row *after* the one we want to scroll to
//			// and work our way back up about 90 pixels to make sure that the 
//			// comment options are visible.
//			NSIndexPath * nextRow = [NSIndexPath indexPathForRow:scrollRow.row + 1 inSection:0];
//			CGRect rect = [tableView rectForRowAtIndexPath:nextRow];
//			rect.origin.y = rect.origin.y - 90;
//			rect.size.height = 90;
//			[tableView scrollRectToVisible:rect animated:YES];
//		}
//	}
//
//	NSLog(@"Selected Row %d", indexPath.row);
////	[affectedRows release];
//}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

//- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	NSLog(@"indentation level in()");
//	return 200.0;
//}
//
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
//	NSLog(@"should indent in(%d)", indexPath.row);
//	CommentCell * cell = (CommentCell * ) [tableView cellForRowAtIndexPath:indexPath];
//	return [cell isEditing];
//	if (indexPath.row == editing_row)
//		return YES;
//	else
//		return NO;
	return YES;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


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
	[bodyHeightCache release];
	[comments release];
	[flatComments release];
//	[filteredListContent release];
    [super dealloc];
}

//#pragma mark -
//#pragma mark Content Filtering
//
//- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
//{
//	/*
//	 Update the filtered array based on the search text and scope.
//	 */
//
//	
//	[filteredListContent removeAllObjects]; // First clear the filtered array.
//
//
//	for (NSDictionary * comment in comments)
//	{
//		NSRange rangeBody = [[comment valueForKey:@"body"] rangeOfString:searchText options:NSCaseInsensitiveSearch ];
//		NSRange rangeUser = [[comment valueForKey:@"author"] rangeOfString : searchText  options:NSCaseInsensitiveSearch];
//		if (rangeBody.location != NSNotFound || rangeUser.location != NSNotFound)
//			[self.filteredListContent addObject:comment];
//	}
//
//}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

//- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
//{
//    [self filterContentForSearchText:searchString scope:
//	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
//    
//    // Return YES to cause the search result table view to be reloaded.
//    return YES;
//}
//
//
//- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
//{
//    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
//	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
//    
//    // Return YES to cause the search result table view to be reloaded.
//    return YES;
//}
//


- (void)textViewDidBeginEditing:(UITextView *)textView
{
	NSLog(@"textViewDidBeginEditing in");
//	int row = [textView tag];
//	NSIndexPath * ind = [NSIndexPath indexPathForRow:(row + 1) inSection:0];
//	CGRect rect = [[self tableView] rectForRowAtIndexPath:ind];
//	rect.origin.y = rect.origin.y - 150;
//	rect.size.height = 150;
//	[[self tableView] scrollRectToVisible:rect animated:YES];
//	[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//	CommentCell * cell = (CommentCell *) [[[[textView superview] superview] superview] superview];
//	[[cell submitReply] setHidden:FALSE];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	NSLog(@"textViewDidEndEditing in");	
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
	NSLog(@"shouldChangeTextInRange in");	

	NSMutableDictionary * comment = (NSMutableDictionary *) [comments objectAtIndex:[textView tag]];
	[comment setValue:[textView text] forKey:@"replyText"];
	
	//	int edit_row = [textView tag];
//	NSLog(@"editing row : %d", edit_row);
	
    // Any new character added is passed in as the "text" parameter
    if ([text isEqualToString:@"\n"]) {
        // Be sure to test for equality using the "isEqualToString" message
        [textView resignFirstResponder];
		
        // Return FALSE so that the final '\n' character doesn't get added
        return FALSE;
    }
    // For any other character return TRUE so that the text gets added to the view
    return TRUE;
}

-(IBAction) popupExtraOptionsActionSheet:(id) sender {
	NSLog(@"pop up extra options in()");
	
	if (!comments || [comments count] == 0)
		return;
	
	
	NSString * loadImageTitle;
	if (![MKStoreManager isProUpgraded])
		loadImageTitle = @"Show All Images (PRO)";
	else
		loadImageTitle = @"Show All Images";	
	
	UIActionSheet *popupQuery = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:nil
								 destructiveButtonTitle:nil
								 otherButtonTitles:
								 @"Open in Safari",
								 @"Email Link",
								 @"Show All Images",
								 nil];
//	NSMutableDictionary * ps = (NSMutableDictionary *) [comments objectAtIndex:0];
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	NSMutableDictionary * ps = [nc post];
	
	// Open in Safari
	// Email Link
	// Load All Images
	// Save Post
	// Hide Post
	// Add Comment
	
	if ([[ps valueForKey:@"saved"] boolValue])
		[popupQuery addButtonWithTitle:@"Un-Save Post"];
	else
		[popupQuery addButtonWithTitle:@"Save Post"];

	if ([[ps valueForKey:@"hidden"] boolValue])
		[popupQuery addButtonWithTitle:@"Un-Hide Post"];
	else
		[popupQuery addButtonWithTitle:@"Hide Post"];
	
	[popupQuery addButtonWithTitle:@"Add a Comment"];
	[popupQuery addButtonWithTitle:@"Cancel"];
	[popupQuery setCancelButtonIndex:6];
	
	popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[popupQuery showInView:self.tabBarController.view];
	[popupQuery release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {

	NSMutableDictionary * ps = (NSMutableDictionary *) [comments objectAtIndex:0];	
	
	if (buttonIndex == 0) {
		NSLog(@"Action Sheet :: Open in Safari");
		NSString * message = @"This will launch Safari and exit Alien Blue.  Do you want to continue?";
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open in Safari"
														message:message
													   delegate:self
											  cancelButtonTitle:@"No"
											  otherButtonTitles:@"Yes",nil];
		[alert setTag:2];
		[alert show];
		[alert release];			
		
	} else if (buttonIndex == 1) {
		NSLog(@"Action Sheet :: Email Link");
		NSString * message = @"This will launch your Mail application and exit Alien Blue.  Do you want to continue?";
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Link"
														message:message
													   delegate:self
											  cancelButtonTitle:@"No"
											  otherButtonTitles:@"Yes",nil];
		[alert setTag:1];
		[alert show];
		[alert release];			
		
	} else if (buttonIndex == 2)
	{
		[self loadAllImages];
	}
	else if (buttonIndex == 3)
	{
		[self toggleSavePost:ps];
	}
	else if (buttonIndex == 4)
	{
		[self toggleHidePost:ps];
	}
	else if (buttonIndex == 5)
	{
		[self showReplyAreaForComment:ps];
		NSIndexPath * ind = [NSIndexPath indexPathForRow:0 inSection:0];
		[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	}
	
	
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	if(alertView.tag == 1 && buttonIndex == 1)
	{
		NSLog(@"launch Mail app in()");
		NSString *url = [NSString stringWithString:@"mailto:?subject=Link%20From%20Reddit&body=http://www.reddit.com"];
		url = [url stringByAppendingString:[[[nc post] valueForKey:@"permalink"] copy]];
		NSLog(url);
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
	}
	
	if(alertView.tag == 2 && buttonIndex == 1)
	{
		NSLog(@"launch safari in()");
		NSString *url = [NSString stringWithFormat:@"http://www.reddit.com%@",[[[nc post] valueForKey:@"permalink"] copy]];		
		NSLog(url);
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	}

	if(alertView.tag == 3 && buttonIndex == 1)	
	{
		NSLog(@"loadAllImages in()");
		
		for (NSMutableDictionary * link in allLinks)
		{
			if ([[link valueForKey:@"type"] isEqualToString:@"image"])
			{
				NSLog(@"downloading image: %@", [link valueForKey:@"url"]);
				[self loadImageInline:link];
			}
		}	
	}
}

@end

