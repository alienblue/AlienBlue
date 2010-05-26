//
//  MessagesTableViewController.m
//  Alien Blue
//
//  Created by Jason Morrissey on 16/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "MessagesTableViewController.h"
#import "NavigationController.h"
#import "AlienBlueAppDelegate.h"


@implementation MessagesTableViewController

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

- (IBAction)linkClicked:(id)sender {
	UIButton * button = (UIButton *) sender;
	NSDictionary * message = [messages objectAtIndex:[[button superview] tag]];
	NSMutableDictionary * link = [[message valueForKey:@"links"] objectAtIndex:[button tag] - 1];
	NSLog(@"-- message row: %d", [[button superview] tag]);
	NSLog(@"-- link #: %d", [button tag]);
	NSLog(@"-- URL : %@", [link valueForKey:@"url"]);
	NavigationController * nc = (NavigationController *) [self parentViewController];
	[nc browseToLinkFromMessage:link];
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


- (void)viewDidLoad {
	NSLog(@"-- messages view loaded --");
    [super viewDidLoad];
	prefs = [NSUserDefaults standardUserDefaults];
	redAPI = [(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] redditAPI];	
//	[messagesTab setBadgeValue:@"None"];
	resultsFetched = NO;


    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//	[self.navigationController setNavigationBarHidden:NO animated:NO];
//	self.navigationItem.rightBarButtonItem = self.editButtonItem;

}



- (void)viewWillAppear:(BOOL)animated {
	NSLog(@"-- messages view will appear --");
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
	NSLog(@"-- messages view appeared --");
    [super viewDidAppear:animated];

	NavigationController * nc = (NavigationController *) [self parentViewController];
	[[self tableView] setScrollsToTop:[[prefs valueForKey:@"allow_status_bar_scroll"] boolValue]];		

	if (![redAPI authenticated])
	{
		[redAPI showAuthorisationRequiredDialog];
		
		// direct user to settings

		[nc setSelectedIndex:2];
		return;
	}

	if ([nc shouldRefreshMessages])
	{
	//	[messages release];
	//	[[self tableView] reloadData];
		[messages removeAllObjects];
		[self fetchMessages:nil];
	} else 
	{
		// This is used when we want to come back from the BrowserView to our messages.  Otherwise
		// we will lose our place.
		// don't do anything this time, but refresh the next time the user taps the Messages
		[nc setShouldRefreshMessages:YES];		
	}
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [messages count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!messages)
		return 150;
	
	if (indexPath.row == [messages count])
		return 150;
	
	float cs = 0;
	
	UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
//	CGSize constraintSize;
	NSDictionary * message = [messages objectAtIndex:indexPath.row];
//	if ([message objectForKey:@"showOptions"] && [[message valueForKey:@"showOptions"] boolValue])
//		constraintSize = CGSizeMake([tableView frame].size.width - 90.0, MAXFLOAT);			
//	else
//		constraintSize = CGSizeMake([tableView frame].size.width - 50.0, MAXFLOAT);
	CGSize constraintSize = CGSizeMake([tableView frame].size.width - 50.0, MAXFLOAT);	
	CGSize labelSize = [[message valueForKey:@"body"] sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	cs = labelSize.height + 20;

	
	if ([message objectForKey:@"showReplyArea"] && [[message valueForKey:@"showReplyArea"] boolValue])	
	{
		cs += 140;
	}	

	for (NSDictionary * link in [message objectForKey:@"links"])
	{
		cs += 50;
	}	
	
	cs += 50;
	return cs;
}

- (UITableViewCell *) createNothingHereCell
{
	UITableViewCell * nCell = [[UITableViewCell alloc] init];
	UILabel * nothingHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 25, 230, 40)];
	[nothingHereLabel setTextAlignment:UITextAlignmentCenter];
	[nothingHereLabel setText:@"You have no messages."];
	[nothingHereLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[nothingHereLabel setBackgroundColor:[UIColor clearColor]];
	[nothingHereLabel setTextColor:[UIColor whiteColor]];
	[nothingHereLabel setFont:[UIFont systemFontOfSize:19]];
	[nCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[nCell addSubview:nothingHereLabel];
	[nCell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	return nCell;
}

- (UITableViewCell *) createViewMoreCell
{
	UITableViewCell * moreCell = [[UITableViewCell alloc] init];
	[moreCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	UIButton * showMoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	CGRect buttonFrame = CGRectMake(60, 25, 200, 40);
	[showMoreButton setFrame:buttonFrame];
	UIProgressView * progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	CGRect progressFrame = CGRectMake(60, 75, 200, 40);
	[progress setFrame:progressFrame];
	
	if ([redAPI loadingMessages])
		[showMoreButton setTitle:@"Loading..." forState:UIControlStateNormal];
	else
		[showMoreButton setTitle:@"Show more..." forState:UIControlStateNormal];
	[showMoreButton setTitleColor:[Resources cNormal] forState:UIControlStateNormal];
	[showMoreButton setTitleColor:[Resources cTitleColor] forState:UIControlStateDisabled];
	[showMoreButton setBackgroundImage:[Resources barImage] forState:UIControlStateNormal];
	
	[showMoreButton addTarget:self action:@selector(fetchMessages:) forControlEvents:UIControlEventTouchUpInside];					
	[moreCell addSubview:showMoreButton];
	
	// hide the progress bar when it isn't in use.
	if ([redAPI loadingMessages])
	{
		[progress setHidden:NO];	
		[progress setProgress:ProgressValue];
		[showMoreButton setEnabled:FALSE];
	}
	else
	{
		[showMoreButton setEnabled:TRUE];		
		[progress setHidden:YES];
	}
	
	[progress setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];	
	[showMoreButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[moreCell setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
	[moreCell addSubview:progress];	
	return moreCell;
}

- (void) deleteOldLinkButtonsForCell:(MessageCell *) cell
{
	NSArray * subviews = [cell subviews];
	//	NSLog(@"-----------");	
	for (id subview in subviews)
	{
//		NSLog(@"-- found object : %@", [subview class]);
		if ([subview isKindOfClass:[UIButton class]])
		{
			UIButton * uib = (UIButton *) subview;
			// only link buttons have a background, so it is safe to remove them
			if ([uib backgroundImageForState:UIControlStateNormal])
				[uib removeFromSuperview];
		}
	}	
}

- (void) createLinkButtonsForCell:(MessageCell *) cell withMessage:(NSDictionary *) comment
{
	NSArray * links = [comment objectForKey:@"links"];

	// need to calculate starting point to draw from... (so that the first link appears above
	//the others.  This is complicated, because the links are bottom-flexy spaced.
	
	float distance_from_bottom = 0;
	for (NSDictionary * link in links)
	{
		NSLog(@"link found: %@", [link valueForKey:@"url"]);
		float frame_height = 33;
		distance_from_bottom += frame_height + 10;
	}
	
	if ([comment objectForKey:@"showReplyArea"] && [[comment valueForKey:@"showReplyArea"] boolValue])
	{
		distance_from_bottom += 135;
	}
	
	float upto = 0;
	float cell_height = [cell frame].size.height;
	float cell_width = [cell frame].size.width;
	int link_counter = 1;
	for (NSMutableDictionary * link in links)
	{
		UIButton * linkButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		
		CGRect frame = CGRectMake(25, cell_height - 55, cell_width - 45, 35);
		float frame_height;
		if ([link objectForKey:@"linkHeight"] && [link objectForKey:@"image"])
			frame_height = [[link valueForKey:@"linkHeight"] floatValue];
		else
			frame_height = 33;
		
		upto += frame_height + 10;
		
		frame.origin.y = frame.origin.y - distance_from_bottom + upto - 5;
		NSString * labelText = [[NSString alloc] initWithFormat:@"    %d :: %@ :: %@                     ",
								[[link valueForKey:@"linkTag"] intValue], [[link valueForKey:@"type"] capitalizedString],
								[link valueForKey:@"description"]];
		[linkButton setFrame:frame];
		[linkButton setHidden:FALSE];
		[linkButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:13]];
		[linkButton setTitle:labelText forState:UIControlStateNormal];
		[linkButton setAutoresizesSubviews:YES];
		[linkButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
		
		[linkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[linkButton setBackgroundImage:[Resources barImage] forState:UIControlStateNormal];
		[cell addSubview:linkButton];
		[linkButton setTag:link_counter];
		[link setValue:[[NSString alloc] initWithFormat:@"%f",frame.size.height] forKey:@"linkHeight"];
		[linkButton addTarget:self action:@selector(linkClicked:) forControlEvents:UIControlEventTouchUpInside];				
		link_counter++;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	// empty set
	if (indexPath.row == 0 && [messages count] == 0 && resultsFetched)
	{
		return [self createNothingHereCell];
	}
	
	if (indexPath.row == [messages count])
		return [self createViewMoreCell];	
    
    static NSString *CellIdentifier = @"MessageCell";
    
    MessageCell *cell = (MessageCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CustomMessageCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[MessageCell class]])
			{
				cell = (MessageCell *)currentObject;
				break;
			}
		}
    }
    // Set up the cell...
	int message_row = indexPath.row;

	[self deleteOldLinkButtonsForCell:cell];
	
	NSDictionary * message = [messages objectAtIndex:indexPath.row];
	[cell setTag:message_row];
	[[cell body] setText:[message valueForKey:@"body"]];
//	[[cell body] setEditable:NO];
	[[cell body] setDataDetectorTypes:UIDataDetectorTypeNone];
//	[[cell body] setUserInteractionEnabled:YES];
	[[cell author] setText:[message valueForKey:@"author"]];

	[[cell showReplyAreaButton]	setTag:message_row];
	[[cell submitReply]	setTag:message_row];	
	[[cell cancelReply]	setTag:message_row];	
	[[cell showContextButton] setTag:message_row];	
	
	[[cell showReplyAreaButton] addTarget:self action:@selector(showReplyAreaPressed:) forControlEvents:UIControlEventTouchUpInside];
	[[cell submitReply] addTarget:self action:@selector(submitReplyPressed:) forControlEvents:UIControlEventTouchUpInside];
	[[cell cancelReply] addTarget:self action:@selector(cancelReplyPressed:) forControlEvents:UIControlEventTouchUpInside];
	[[cell showContextButton] addTarget:self action:@selector(messageContextPressed:) forControlEvents:UIControlEventTouchUpInside];
	[[cell replyTextView] setDelegate:self];
	[[cell replyTextView] setText:@""];

	if ([[message valueForKey:@"was_comment"] boolValue])
		[[cell showContextButton] setHidden:NO];
	else
		[[cell showContextButton] setHidden:YES];		
		
	if ([message objectForKey:@"showReplyArea"] && [[message valueForKey:@"showReplyArea"] boolValue])
	{	
		[[cell viewForMessageReply] setHidden:FALSE];
	}
	else
		[[cell viewForMessageReply] setHidden:TRUE];
	[[cell replyTextView] setTag:message_row];
	

	// parse links and add related buttons
	if ([[message objectForKey:@"links"] count] > 0)
	{
		[self createLinkButtonsForCell:cell withMessage:message];		
	}		

	
	
//	UITextView * messageBody = [[UITextView alloc] initWithFrame:CGRectMake(20, 20, 290, 50)];
//	[messageBody setText:[message valueForKey:@"body"]];
//	[messageBody setBackgroundColor:[UIColor clearColor]];
//	[messageBody setFont:[UIFont fontWithName:@"Helvetica" size:14]];
//	[messageBody setScrollEnabled:FALSE];
//	[messageBody setEditable:FALSE];
//	[messageBody setTextColor:[UIColor whiteColor]];
//	[messageBody setAutoresizesSubviews:FALSE];
//	[messageBody setClipsToBounds:FALSE];
//
//	[cell setClipsToBounds:TRUE];
//	[cell addSubview:messageBody];
    return cell;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	int row = [textView tag];
	NSIndexPath * ind = [NSIndexPath indexPathForRow:row inSection:0];
	[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
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

- (IBAction)messageContextPressed:(id)sender {
	UIButton *button = (UIButton *)sender;	
	NSDictionary * message = [messages objectAtIndex:[button tag]];

	
	if (![[message valueForKey:@"was_comment"] boolValue])
		return;
	
	NSString * context = [message valueForKey:@"context"];
	if (!context || [context length] == 0)
		return;
	
	NSString * post_id = nil;
	int post_id_left = [context rangeOfString:@"/comments/" options:NSCaseInsensitiveSearch].location;
	if (post_id_left != NSNotFound)
	{
		post_id_left += 10;
		int post_id_right = [[context substringFromIndex:post_id_left] rangeOfString:@"/" options:NSCaseInsensitiveSearch].location;
		if (post_id_right != NSNotFound)
		{
			post_id = [context substringWithRange:NSMakeRange(post_id_left, post_id_right)];
			NSLog(@"Context Post ID : %@", post_id);
		}
	}
	
	if (!post_id)
		return;
	
	NavigationController * nc = (NavigationController *) [self parentViewController];
	[nc setReplyCommentID:[message valueForKey:@"name"]];
	NSMutableDictionary * post = [[NSMutableDictionary alloc] init];
	[post setValue:post_id forKey:@"id"];
	[post setValue:@"" forKey:@"type"];
	[nc browseToPostThreadFromMessage:post];
}

- (IBAction)cancelReplyPressed:(id)sender {
	NSLog(@"cancelReplyPressed in()");
	UIButton *button = (UIButton *)sender;	
	NSDictionary * message = [messages objectAtIndex:[button tag]];
	[message setValue:@"NO" forKey:@"showReplyArea"];
	[self refreshRow:[button tag]];	
}

- (IBAction)showReplyAreaPressed:(id)sender {
	NSLog(@"showReplyAreaPressed in()");
	UIButton *button = (UIButton *)sender;	
	NSDictionary * message = [messages objectAtIndex:[button tag]];
	[message setValue:@"YES" forKey:@"showReplyArea"];
	int row = [button tag];

	[self refreshRow:[button tag]];		
	NSIndexPath * ind = [NSIndexPath indexPathForRow:row inSection:0];
	[[self tableView] scrollToRowAtIndexPath:ind atScrollPosition:UITableViewScrollPositionBottom animated:YES];

}

- (IBAction)submitReplyPressed:(id)sender {
	NSLog(@"submitReplyPressed in()");
	UIButton *button = (UIButton *)sender;	
	NSMutableDictionary * message = [messages objectAtIndex:[button tag]];
	MessageCell * cell = (MessageCell *) [[[[button superview] superview] superview] superview];
	[message setValue:[[cell replyTextView] text] forKey:@"replyText"];
	NavigationController * nc = (NavigationController *) [self parentViewController];
	NSLog([message valueForKey:@"replyText"]);
	[nc replyToItem:message];
	[message setValue:@"NO" forKey:@"showReplyArea"];
	[self refreshRow:[button tag]];	
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
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
    [super dealloc];
}

- (NSString *) reformatBody:(NSString *) body
{
	body = [body stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
	body = [body stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
	body = [body stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	return body;
}

- (IBAction)apiInboxResponse:(id)sender
{
	NSLog(@"-- apiInboxResponse");
	NSMutableDictionary *data = (NSMutableDictionary *) sender;
	
	for (NSMutableDictionary * message_data in [[data objectForKey:@"data"] objectForKey:@"children"])
	{
		NSMutableDictionary * message = [message_data objectForKey:@"data"];
		CommentsTableViewController *ctvc = [(NavigationController *) [self parentViewController] commentsView];
		[ctvc reformat:message];
//		NSString * body = [self reformatBody:[message valueForKey:@"body"]];
//		[message setValue:body forKey:@"body"];

		[messages addObject:message];
	}

//	if (unreadMailCount > 0)
//	{
//		UITabBarController * tb = [(NeuRedditAppDelegate *) [[UIApplication sharedApplication] delegate] tabBarController];	
//		UITabBarItem *  messagesTab = [[[tb tabBar] items] objectAtIndex:1];
//		[messagesTab setBadgeValue:[NSString stringWithFormat:@"%d",unreadMailCount]];
//	}
	
	//	[posts addObjectsFromArray:[[data objectForKey:@"data"] objectForKey:@"children"]];
	
	NSLog(@"Imported %d", [messages count]);
	
	[[self tableView] reloadData];
	[self completeProgressBar];
	resultsFetched = YES;
	
}


- (IBAction) fetchMessages:(id)sender
{
	UIButton * button = (UIButton *) sender;
	if (button)
		[button setEnabled:FALSE];
	[self enableProgressBar];
	NSLog(@"Show more messages...");
	NSString * afterMessageID = @"";
	if (!messages)
	{
		messages = [[NSMutableArray alloc] init];
	}
	
	if ([messages count] > 0)
	{
		NSDictionary * lastMessage = [messages objectAtIndex:([messages count] - 1)];
		afterMessageID = [lastMessage valueForKey:@"name"];
		NSLog(@"asking for messages after id [%@]", afterMessageID);
	}
	[redAPI fetchMessageInboxAfterMessageID:afterMessageID withCallBackTarget:self];
	
	[[self tableView] reloadData];
}



@end

