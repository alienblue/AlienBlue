//
//  CommentWrapper.m
//  Alien Blue
//
//  Created by Jason Morrissey on 23/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "CommentWrapper.h"


@implementation CommentWrapper
@synthesize comment;
@synthesize commentsController;

+ (void)initialize {
	// Unlikely to have any subclasses, but check class nevertheless.
	if (self == [CommentWrapper class]) {
//		today = [NSLocalizedString(@"Today", "Today") retain];
//		tomorrow = [NSLocalizedString(@"Tomorrow", "Tomorrow") retain];
//		yesterday = [NSLocalizedString(@"Yesterday", "Yesterday") retain];
//		
//		q1Image = [[UIImage imageNamed:@"12-6AM.png"] retain];
//		q2Image = [[UIImage imageNamed:@"6-12AM.png"] retain];
//		q3Image = [[UIImage imageNamed:@"12-6PM.png"] retain];
//		q4Image = [[UIImage imageNamed:@"6-12PM.png"] retain];	
	}
}


- initWithComment:(NSMutableDictionary *)cDictionary forController:(UIViewController *) viewController {
	
	if (self = [super init]) {
		comment = [cDictionary retain];
		commentsController = (CommentsTableViewController* ) viewController;
	}
	return self;
}


- (void)dealloc {
    [super dealloc];
}


@end
