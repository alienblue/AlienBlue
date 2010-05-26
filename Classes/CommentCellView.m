//
//  CommentCellView.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 23/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "CommentCellView.h"
#import "CommentsTableViewController.h"
#import "Resources.h"
static UIImage *levelArrowImage;

static UIImage *saveIcon;
static UIImage *saveSelectedIcon;
static UIImage *hideIcon;
static UIImage *hideSelectedIcon;

static UIImage *voteUpIcon;
static UIImage *voteUpSelectedIcon;
static UIImage *voteDownIcon;
static UIImage *voteDownSelectedIcon;
static UIImage *contextIcon;
static UIImage *replyIcon;
static UIImage *editIcon;

@implementation CommentCellView

@synthesize commentWrapper;
@synthesize replyTextView;

+ (void)initialize {
	// Unlikely to have any subclasses, but check class nevertheless.
	if (self == [CommentCellView class]) {
		NSLog(@"CCV :: CommentCellView initialise in()");
		levelArrowImage = [[UIImage imageNamed:@"level-arrows.png"] retain];	

		voteUpIcon = [[UIImage imageNamed:@"vote-up.png"] retain];
		voteUpSelectedIcon = [[UIImage imageNamed:@"vote-up-selected.png"] retain];
		voteDownIcon = [[UIImage imageNamed:@"vote-down.png"] retain];
		voteDownSelectedIcon = [[UIImage imageNamed:@"vote-down-selected.png"] retain];
		contextIcon = [[UIImage imageNamed:@"comment-parent-icon.png"] retain];
		replyIcon = [[UIImage imageNamed:@"reply.png"] retain];
		editIcon = [[UIImage imageNamed:@"edit-icon.png"] retain];		

		saveIcon = [[UIImage imageNamed:@"star-icon.png"] retain];		
		saveSelectedIcon = [[UIImage imageNamed:@"star-selected-icon.png"] retain];
		hideIcon = [[UIImage imageNamed:@"hide-icon.png"] retain];
		hideSelectedIcon = [[UIImage imageNamed:@"hide-selected-icon.png"] retain];

	}
}

- (id)initWithFrame:(CGRect)frame {
//	NSLog(@"CCV :: initWithFrame in()");
	if (self = [super initWithFrame:frame]) {
//		self.opaque = YES;
//		self.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.2 alpha:1];
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)setCommentWrapper:(CommentWrapper *)newCommentWrapper {
	
	if (commentWrapper != newCommentWrapper) {
		[commentWrapper release];
		commentWrapper = [newCommentWrapper retain];
	}
	// May be the same wrapper, but the date may have changed, so mark for redisplay.
	[self setNeedsDisplay];
}

- (void) handleOptionsTouchesForPoint:(CGPoint) touchPoint
{
	bool isPostInfo = [[[commentWrapper comment] valueForKey:@"comment_index"] intValue] == 0;
	
	if (isPostInfo)
	{
		if (touchPoint.x < 50)
			[(CommentsTableViewController *) [commentWrapper commentsController] toggleSavePost:[commentWrapper comment]];
		else if (touchPoint.x > 50 && touchPoint.x < 115)
			[(CommentsTableViewController *) [commentWrapper commentsController] toggleHidePost:[commentWrapper comment]];
	}

	if (touchPoint.x < 60 && !isPostInfo)
		[(CommentsTableViewController *) [commentWrapper commentsController] contextForComment:[commentWrapper comment]];
	else if (touchPoint.x > (self.bounds.size.width / 2 - 20) && 
			 touchPoint.x < (self.bounds.size.width / 2 + 20))
	{
		// if the authenticated user clicks this area - activate edit mode, otherwise
		// activate standard comment reply.
		if ([[[commentWrapper comment] valueForKey:@"comment_type"] isEqualToString:@"me"])
			[(CommentsTableViewController *) [commentWrapper commentsController] editModeForComment:[commentWrapper comment]];
		else
			[(CommentsTableViewController *) [commentWrapper commentsController] showReplyAreaForComment:[commentWrapper comment]];		
	}
	else if (touchPoint.x > (self.bounds.size.width - 100) && 
			 touchPoint.x < (self.bounds.size.width - 40))
		[(CommentsTableViewController *) [commentWrapper commentsController] voteUpComment:[commentWrapper comment]];
	else if (touchPoint.x > (self.bounds.size.width - 40)) 
		[(CommentsTableViewController *) [commentWrapper commentsController] voteDownComment:[commentWrapper comment]];
	
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	gestureStartPoint = [[touches anyObject] locationInView:self];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"hitTest in");
	CGPoint touchPoint = [[touches anyObject] locationInView:self];

	// check swipe from on top bar
	if (touchPoint.y < 70 && fabs(gestureStartPoint.x - touchPoint.x) > 50)
	{
		NSLog(@"top bar swiped");
		[(CommentsTableViewController *)  [commentWrapper commentsController] collapseToRootForComment:[commentWrapper comment]];
		return;
	}
	
	// top bar button pressed
	if (touchPoint.y < 50)
	{
		[(CommentsTableViewController *) [commentWrapper commentsController] toggleComment:[commentWrapper comment]];
		return;
	}
	else if (touchPoint.y > (self.bounds.size.height - 50) && 
			 [[commentWrapper comment] objectForKey:@"showOptions"] && 
			 [[[commentWrapper comment] valueForKey:@"showOptions"] boolValue])
	{
		NSLog(@"options area clicked");
		[self handleOptionsTouchesForPoint:touchPoint];
		return;
	}
	else if (touchPoint.y > 50)
	{
		NSLog(@"body touched at row %d", [[[commentWrapper comment] valueForKey:@"comment_index"] intValue]);
		[(CommentsTableViewController *) [commentWrapper commentsController] selectComment:[commentWrapper comment]];		
//		[super touchesEnded:touches withEvent:event];
	}
//	NSLog(@"touch position : %f", touchPoint.y);

}

- (void)drawReplyArea
{
	float bound_height = self.bounds.size.height;
	float bound_width =  self.bounds.size.width;

	replyTextView = [[[UITextView alloc] initWithFrame:CGRectMake(20, bound_height - 130,  bound_width - 40, 70)] retain];
	[replyTextView setText:[[commentWrapper comment] valueForKey:@"replyText"]];
	[replyTextView setDelegate:(CommentsTableViewController *) [commentWrapper commentsController]];
	[replyTextView setTag:[[[commentWrapper comment] valueForKey:@"comment_index"] intValue]];
	[replyTextView setReturnKeyType:UIReturnKeyDone];
	[replyTextView setScrollsToTop:YES];
	[replyTextView setEnablesReturnKeyAutomatically:NO];
	[replyTextView setFont:[Resources secondaryFont]];
	[self addSubview:replyTextView];
	
	UIButton * cancelButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	[cancelButton setFrame:CGRectMake(20, bound_height - 45, 90, 30)];
	[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
	[cancelButton setTag:[[[commentWrapper comment] valueForKey:@"comment_index"] intValue]];
	[cancelButton addTarget:[commentWrapper commentsController] action:@selector(cancelReplyPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:cancelButton];

	UIButton * submitButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	[submitButton setFrame:CGRectMake(bound_width - 110, bound_height - 45, 90, 30)];
	[submitButton setTitle:@"Submit" forState:UIControlStateNormal];
	[submitButton setTag:[[[commentWrapper comment] valueForKey:@"comment_index"] intValue]];
	[submitButton addTarget:[commentWrapper commentsController] action:@selector(submitReplyPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:submitButton];
	
}

- (float) drawPostInfo
{
	float vertical_offset = 60;
	
	NSDictionary * comment = [commentWrapper comment];		
	float bound_width =  self.bounds.size.width;

//	CGContextRef context = UIGraphicsGetCurrentContext(); 
//	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1); 	
//	CGRect rect = CGRectMake(0, 0, self.bounds.size.width, bound_height);
//	CGContextFillRect(context, rect);
	
	[[Resources cNormal] set];	
	NSDate * d = [NSDate dateWithTimeIntervalSince1970:[[comment valueForKey:@"created"] doubleValue]];
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
	[[df stringFromDate:d] drawInRect:CGRectMake(15, vertical_offset, bound_width - 30, 20) withFont:[Resources tertiaryFont]];
	[df release];
	
	NSString * commentsString = [NSString stringWithFormat:@"%d comments", [[comment valueForKey:@"num_comments"] intValue]];
	[commentsString drawInRect:CGRectMake(bound_width - 35 - ([commentsString length] * 5), vertical_offset, 300, 20) withFont:[Resources tertiaryFont]];	
	
	vertical_offset += 20;

	[[comment valueForKey:@"url"] drawInRect:CGRectMake(15, vertical_offset, bound_width - 20, 20) withFont:[Resources tertiaryFont]];

	vertical_offset += 30;	
	
	[[Resources cTitleColor] set];
	CGRect titleFrame = CGRectMake(15, vertical_offset, bound_width - 30, 300 - 20);
	
	CGSize constraintSize = CGSizeMake(bound_width - 50.0, MAXFLOAT);
	CGSize labelSize = [[comment valueForKey:@"title"] sizeWithFont:[Resources mainFont] constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	vertical_offset += labelSize.height + 15;
	
	[[comment valueForKey:@"title"] drawInRect:titleFrame withFont:[Resources mainFont]];	


	
	vertical_offset -= 60;	
	
	return vertical_offset;
	
	//	[[self superview] setOpaque:FALSE];
//	[self setBackgroundColor:[UIColor clearColor]];
	
//	[self setOpaque:FALSE];
}

- (void)drawOptions
{
	float bound_height = self.bounds.size.height;
	float bound_width =  self.bounds.size.width;
	float vertical_offset =  bound_height - 50;
	CGContextRef context = UIGraphicsGetCurrentContext(); 
	CGContextSetRGBFillColor(context, 0.05, 0.05, 0.05, 0.4); 	
	CGRect rect = CGRectMake(0, vertical_offset, self.bounds.size.width, 50);
	CGContextFillRect(context, rect);
	NSMutableDictionary * comment = [commentWrapper comment];
	
	if ([[comment valueForKey:@"level"] intValue] > 0)
		[contextIcon drawAtPoint:CGPointMake(5, vertical_offset + 13)];

	if ([[comment valueForKey:@"comment_type"] isEqualToString:@"me"])	
		[editIcon drawAtPoint:CGPointMake(bound_width / 2 - 15, vertical_offset + 11)];
	else
		[replyIcon drawAtPoint:CGPointMake(bound_width / 2 - 15, vertical_offset + 11)];

	[voteUpIcon drawAtPoint:CGPointMake(bound_width - 100, vertical_offset + 9)];
	[voteDownIcon drawAtPoint:CGPointMake(bound_width - 40, vertical_offset + 11)];
	
	if ([[comment valueForKey:@"voteDirection"] intValue] > 0)
	{
		[voteUpSelectedIcon drawAtPoint:CGPointMake(bound_width - 100, vertical_offset + 9)];
	} else if ([[[commentWrapper comment] valueForKey:@"voteDirection"] intValue] < 0)
	{
		[voteDownSelectedIcon drawAtPoint:CGPointMake(bound_width - 40, vertical_offset + 11)];
	}
	
	// draw options for the Post Information cell (like Save and gn)
	if ([[comment valueForKey:@"comment_index"] intValue] == 0)
	{
		if ([[comment valueForKey:@"saved"] boolValue])
			[saveSelectedIcon drawAtPoint:CGPointMake(10, vertical_offset + 9)];
		else
			[saveIcon drawAtPoint:CGPointMake(10, vertical_offset + 9)];

		if ([[comment valueForKey:@"hidden"] boolValue])
			[hideSelectedIcon drawAtPoint:CGPointMake(75, vertical_offset + 10)];
		else
			[hideIcon drawAtPoint:CGPointMake(75, vertical_offset + 10)];
	}
}

- (void)drawLinkButtons
{
	NSMutableDictionary * comment = [commentWrapper comment];
	NSArray * links = [comment objectForKey:@"links"];

//	NSLog(@"drawLinkButtons in for (%d)", [[comment valueForKey:@"comment_index"] intValue]);	
	
	int link_counter = 1;
	
	// need to calculate starting point to draw from... (so that the first link appears above
	//the others.  This is complicated, because the links are bottom-flexy spaced.
	
	float distance_from_bottom = 0;
	for (NSDictionary * link in links)
	{
		float frame_height;
		// overwrite frame_height variable if an image has been loaded (to avoid overlapping
		// other links in the same comment.
		if ([link objectForKey:@"linkHeight"] && [link objectForKey:@"image"])
			frame_height = [[link valueForKey:@"linkHeight"] floatValue];
		else
			frame_height = 33;
		distance_from_bottom += frame_height + 10;
	}
	
	if ([comment objectForKey:@"showOptions"] && [[comment valueForKey:@"showOptions"] boolValue])
	{
		distance_from_bottom += 50;
	}	
	
	if ([comment objectForKey:@"showReplyArea"] && [[comment valueForKey:@"showReplyArea"] boolValue])
	{
		distance_from_bottom += 135;
	}
	
	float upto = 0;
	for (NSMutableDictionary * link in links)
	{
		UIButton * linkButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];		
		
		CGRect frame = CGRectMake(20, self.bounds.size.height - 65, self.bounds.size.width - 40, 36);
		
		float frame_height;
		if ([link objectForKey:@"linkHeight"] && [link objectForKey:@"image"])
			frame_height = [[link valueForKey:@"linkHeight"] floatValue];
		else
			frame_height = 33;
		
		upto += frame_height + 10;
		
		frame.origin.y = frame.origin.y - distance_from_bottom + upto - 5;
		//		frame.origin.y = frame.origin.y - ((frame_height + 8) * ([links count] - link_counter));
		NSString * labelText = [NSString stringWithFormat:@"             %d  : %@          ",
								[[link valueForKey:@"linkTag"] intValue], [link valueForKey:@"description"]];

		
		[linkButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
		[linkButton setFrame:frame];
		[linkButton setHidden:FALSE];
		[linkButton setTitle:labelText forState:UIControlStateNormal];
		[linkButton setAutoresizesSubviews:YES];
		[linkButton setBackgroundImage:[Resources barImage] forState:UIControlStateNormal];
		[linkButton.titleLabel setFont:[Resources secondaryFont]];
		[linkButton setTitleColor:[Resources cTitleColor] forState:UIControlStateNormal];
		[linkButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

		[self addSubview:linkButton];
//		[self sendSubviewToBack:linkButton];
//		[imageIcon drawAtPoint:CGPointMake(15,frame.origin.y - 5)];
//		[imageIcon drawInRect:CGRectMake(15,frame.origin.y - 5,50,50)];

//		[imageIcon drawAtPoint:CGPointMake(15,frame.origin.y - 5)];
//		[imageIcon drawAtPoint:CGPointMake(15,frame.origin.y - 5) blendMode:kCGBlendModeDestinationOver alpha:1];
		UIImageView * icon = [[UIImageView alloc] init];

		if ([[link valueForKey:@"type"] isEqualToString:@"video"])
			[icon setImage:[Resources videoIcon]];
		else if ([[link valueForKey:@"type"] isEqualToString:@"image"])
			[icon setImage:[Resources imageIcon]];
		else
			[icon setImage:[Resources articleIcon]];
			
		
		[icon setFrame:CGRectMake(15,frame.origin.y - 5,50,50)];
//		UILabel * linkIdentifier = [[UILabel alloc] initWithFrame:CGRectMake(15,frame.origin.y - 7,45,45)];
//		[linkIdentifier setTextAlignment:UITextAlignmentCenter];
//		[linkIdentifier setText:[[link valueForKey:@"linkTag"] stringValue]];
//		[linkIdentifier setBackgroundColor:[UIColor clearColor]];
//		[linkIdentifier setTextColor:[UIColor whiteColor]];
//		[linkIdentifier setFont:secondaryFont];

		// this is to make sure that open images don't have an unnecessary image
		// icon
		if (![link objectForKey:@"image"])
		{
			[self addSubview:icon];
//			[self addSubview:linkIdentifier];
		}

		UIButton * moreButton = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
		CGRect moreframe = [moreButton frame];
		moreframe.origin.x = [linkButton frame].size.width - moreframe.size.width + 12;
		moreframe.origin.y = frame.origin.y + 2;
		[moreButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
		[moreButton setFrame:moreframe];
		[moreButton setTransform:CGAffineTransformIdentity];
		//		[linkButton addSubview:moreButton];
		[self addSubview:moreButton];
		[linkButton setTag:[[link valueForKey:@"link_id"] integerValue]];
		[moreButton setTag:[[link valueForKey:@"link_id"] integerValue]];
		[link setValue:[NSString stringWithFormat:@"%f",frame.size.height] forKey:@"linkHeight"];
		[linkButton addTarget:[commentWrapper commentsController] action:@selector(linkClicked:) forControlEvents:UIControlEventTouchUpInside];				
		[moreButton addTarget:[commentWrapper commentsController] action:@selector(moreButtonClicked:) forControlEvents:UIControlEventTouchUpInside];		
		if ([link objectForKey:@"image"])
		{
			UIImage * image = (UIImage *) [link objectForKey:@"image"];
			UIImageView * imageView = [[UIImageView alloc] initWithImage:image];
			[imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
			[imageView setContentMode:UIViewContentModeScaleAspectFit];
			CGRect imageFrame = [imageView frame];
			CGRect linkFrame = [linkButton frame];
			CGFloat aspect_ratio = [image size].width / [image size].height;
			//			CGFloat aspect_ratio = imageFrame.size.width / imageFrame.size.height;
			imageFrame.origin.y += linkFrame.size.height;
			imageFrame.origin.x = 5;
			imageFrame.size.width = roundf(linkFrame.size.width - 10);
			imageFrame.size.height = roundf(imageFrame.size.width / aspect_ratio);
			[imageView setFrame:imageFrame];
			//			
			//			[linkButton setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
			[linkButton addSubview:imageView];
			[linkButton setBackgroundImage:nil forState:UIControlStateNormal];

			// We need the roundf() here, otherwise we may end up sizing the picture to something
			// like 1000.1234 pixels.  This would cause aliasing in other elements that are below
			// the image.
			linkFrame.size.height = roundf(imageFrame.size.width / aspect_ratio + linkFrame.size.height + 5);
			
			linkFrame.origin.y -= [imageView frame].size.height;
			moreframe.origin.y = linkFrame.origin.y;
			[moreButton setFrame:moreframe];			
			[link setValue:[NSString stringWithFormat:@"%f",linkFrame
							.size.height] forKey:@"linkHeight"];
			[linkButton setTitle:@"" forState:UIControlStateNormal];
			[linkButton setFrame:linkFrame];
			[linkButton setEnabled:FALSE];
			[linkButton setClipsToBounds:TRUE];
		}
		link_counter++;
	}	
}

- (void)drawRect:(CGRect)rect {

	NSDictionary * comment = [commentWrapper comment];	
//	NSLog(@"CommentCellView :: drawRect :: Row [%d]",[[[self superview] superview] tag]);
	
	// remove cached subviews
	for (UIView * subview in [self subviews])
	{
		[subview removeFromSuperview];
		[subview release];
	}
	
	CGRect contentRect = self.bounds;

	float vertical_offset = 65;
	// top comment is always the post itself
	if ([[comment valueForKey:@"comment_index"] intValue] == 0)
	{
		vertical_offset += [self drawPostInfo];
	}
	
	[[Resources barImage] drawInRect:CGRectMake(-20, 0, contentRect.size.width + 40, 50)];

	// don't extend beyond 3 levels, otherwise we can indent indefinitely
	int level = [[comment valueForKey:@"level"] intValue];
	if (level > 0)
	{
		if (level > 3) level = 3;
		CGImageRef imageRef = CGImageCreateWithImageInRect([levelArrowImage CGImage], CGRectMake(0, 0, level * 25, 30));
		UIImage * arrImage = [UIImage imageWithCGImage:imageRef];
		[arrImage drawAtPoint:CGPointMake(0, 12)];
		CGImageRelease(imageRef);
		
	}
	else level = 0;
	
	if ([[comment valueForKey:@"comment_type"] isEqualToString:@"op"])
		[[Resources cOrange] set];	
	else if ([[comment valueForKey:@"comment_type"] isEqualToString:@"me"])
		[[Resources cGreen] set];
	else
		[[Resources cTitleColor] set];

	float author_horizontal_offset = level * 25 + 10;

	[[comment valueForKey:@"author"] drawInRect:CGRectMake(author_horizontal_offset, 15, 180 - author_horizontal_offset, 30) withFont:[Resources secondaryFont] lineBreakMode:UILineBreakModeClip];
	 
//	 drawAtPoint:CGPointMake(,15) withFont:secondaryFont];	
	
//	[[comment valueForKey:@"author"] drawAtPoint:CGPointMake(,15) withFont:secondaryFont];

	[[Resources cGreen] set];
	[[[comment valueForKey:@"score"] stringValue] drawAtPoint:CGPointMake(contentRect.size.width - 125,15) withFont:[Resources secondaryFont]];

	[[Resources cTitleColor] set];
	NSString * replies;
	int numReplies = [[comment valueForKey:@"numReplies"] intValue];
	if ([[comment valueForKey:@"comment_index"] intValue] == 0)
		replies = @"Post";
	else if (numReplies == 0)
		replies = @"No replies";
	else if (numReplies == 1)
		replies = @"1 reply";
	else
		replies = [NSString stringWithFormat:@"%d replies",numReplies];
	
	[replies drawInRect:CGRectMake(contentRect.size.width - 100, 15, 90, 30) withFont:[Resources secondaryFont] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
	
	if ([[comment valueForKey:@"visibility"] isEqualToString:@"collapsed"] ||
		[[comment valueForKey:@"visibility"] isEqualToString:@"hidden"])
		return;	
	
	[[Resources cNormal] set];	
	
	if([comment objectForKey:@"links"])
		[self drawLinkButtons];

	if ([comment objectForKey:@"showOptions"] && [[comment valueForKey:@"showOptions"] boolValue])
		[self drawOptions];		

	if ([comment objectForKey:@"showReplyArea"] && [[comment valueForKey:@"showReplyArea"] boolValue])
		[self drawReplyArea];			
	
	
	[[Resources cNormal] set];	
	[[comment valueForKey:@"body"] drawInRect:CGRectMake(15, vertical_offset, contentRect.size.width - 30, contentRect.size.height - 20) withFont:[Resources mainFont]];

	
}


- (void)dealloc {
//	[linkButtons release];
	[commentWrapper release];
    [super dealloc];
}


@end
