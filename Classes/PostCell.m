//
//  PostCell.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "PostCell.h"
#import "PostsTableControllerView.h"

@implementation PostCell

@synthesize post;
@synthesize postController;


static NSUserDefaults * prefs;

+ (void)initialize {
	// Unlikely to have any subclasses, but check class nevertheless.
	if (self == [PostCell class]) {
		NSLog(@"PC :: PostCell initialise in()");
		prefs = [NSUserDefaults standardUserDefaults];		

	}
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		
//		CGRect cellViewFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
//		commentCellView = [[CommentCellView alloc] initWithFrame:cellViewFrame];
//		commentCellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//		[self.contentView addSubview:commentCellView];
//		[self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[self setAccessoryType:UITableViewCellAccessoryNone];
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
		[self setClipsToBounds:YES];
	}
	return self;
}

//- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
//    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
//        // Initialization code
//    }
//    return self;
//}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setPost:(NSMutableDictionary *) newPost {
//	NSLog(@"PostCell :: setPost in()");
	post = newPost;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//	NSLog(@"hitTest in");
	CGPoint touchPoint = [[touches anyObject] locationInView:self];
	if (CGRectContainsPoint(buttonFrame, touchPoint))
	{
		NSLog(@"comments button pressed");
		[(PostsTableControllerView *) postController showCommentsForPost:post];
	}
	else
	{
		[(PostsTableControllerView *) postController openLinkForPost:post];		
	}
	
}

- (IBAction) imageReadyCallback: (id)sender
{
	NSLog(@"** Post Cell : Image Ready Callback");
	[self setNeedsDisplay];

}

- (void) drawThumbnail:(float) vertical_offset
{
//	NSLog(@"* PostCell :: draw thumbnail in");
	UIImage * thumb = [ImageCache imageForURL:[post valueForKey:@"thumbnail"] withCallBackTarget:self];
	if (thumb)
	{
		CGRect thumbFrame = CGRectMake(5, vertical_offset, 65, 47);	
		[thumb drawInRect:thumbFrame];	
	}
	
}

- (void) drawTransparentOverlay
{
	CGContextRef context = UIGraphicsGetCurrentContext(); 
	CGContextSetRGBFillColor(context, 0.05, 0.05, 0.15, 0.7); 	
	CGRect rect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
	CGContextFillRect(context, rect);	
}

- (void)drawRect:(CGRect)rect {
	
//	NSLog(@"Post Cell :: drawRect in()");
	CGRect contentRect = self.bounds;
	
	[[Resources cNormal] set];
	float vertical_offset = 15;
	[[post valueForKey:@"title"] drawInRect:CGRectMake(15, vertical_offset, contentRect.size.width - 45, contentRect.size.height - 20) withFont:[Resources mainFont]];

	CGSize constraintSize = CGSizeMake(contentRect.size.width - 45, MAXFLOAT);
	CGSize labelSize = [[post valueForKey:@"title"] sizeWithFont:[Resources mainFont] constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	vertical_offset += labelSize.height + 15;

	if ([[post valueForKey:@"type"] isEqualToString:@"video"])
		[[Resources videoIcon] drawAtPoint:CGPointMake(15, vertical_offset)];
	else if ([[post valueForKey:@"type"] isEqualToString:@"image"])
		[[Resources imageIcon] drawAtPoint:CGPointMake(15, vertical_offset)];
	else
		[[Resources articleIcon] drawAtPoint:CGPointMake(15, vertical_offset)];

	if ([prefs boolForKey:@"show_thumbs"] && 
		[[post valueForKey:@"thumbnail"] length] > 0)
		[self drawThumbnail:vertical_offset];	
	
	
	NSString * strComments = [NSString stringWithFormat: @"%d comment(s)", [[post objectForKey:@"num_comments"] intValue]];	
	buttonFrame = CGRectMake(80, vertical_offset, 205, 40);
	
	CGRect labelFrame = CGRectMake(80, vertical_offset + 10, 205, 40);	
	[[Resources barImage] drawInRect:buttonFrame];
	[strComments drawInRect:labelFrame withFont:[Resources secondaryFont] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];

	vertical_offset += 50;

	[[[post valueForKey:@"score"] stringValue] drawInRect:CGRectMake(15, vertical_offset, 45, 30) withFont:[Resources tertiaryFont] lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
	
//	[[post valueForKey:@"domain"] drawAtPoint:CGPointMake(84, vertical_offset) withFont:tertiaryFont];
	[[post valueForKey:@"domain"] drawInRect:CGRectMake(84, vertical_offset, 100, 15) withFont:[Resources tertiaryFont] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];	
	[[post valueForKey:@"subreddit"] drawInRect:CGRectMake(196, vertical_offset, self.bounds.size.width - 235, 15) withFont:[Resources tertiaryFont] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
	
	vertical_offset += 20;
	
	CGContextRef context = UIGraphicsGetCurrentContext(); 
	CGContextSetRGBFillColor(context, 0.05, 0.05, 0.15, 0.2); 	
	rect = CGRectMake(0, self.bounds.size.height - 4, self.bounds.size.width, 4);
	CGContextFillRect(context, rect);
	
	[[Resources rightArrowDimImage] drawInRect:CGRectMake(self.bounds.size.width - 22, (vertical_offset / 2) - 5, 17, 26)];
	
//	if (isEditing)
//		[self drawTransparentOverlay];	
	
}

//- (void)setEditing:(BOOL)editing animated:(BOOL)animate
//{
////	isEditing = editing;
////	if ([self contentView])
////		[self setNeedsDisplay];
////	
//	
////	if (post == [NSMutableDictionary class])
////	{
////		if (editing)
////			[post setValue:[NSNumber numberWithBool:YES] forKey:@"editing"];
////		else
////			[post setValue:[NSNumber numberWithBool:NO] forKey:@"editing"];
////		[self setNeedsDisplay];
////	}
//		
//	[super setEditing:editing animated:animate];
//}


- (void)dealloc {
    [super dealloc];
}


@end
