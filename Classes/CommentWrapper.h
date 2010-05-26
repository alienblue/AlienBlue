//
//  CommentWrapper.h
//  Alien Blue
//
//  Created by Jason Morrissey on 23/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//
@class CommentsTableViewController;

@interface CommentWrapper : NSObject {
	NSMutableDictionary * comment;
	CommentsTableViewController *  commentsController;
}
- initWithComment:(NSMutableDictionary *)cDictionary forController:(UIViewController *) viewController;
@property (nonatomic, retain) NSMutableDictionary *comment;
@property (nonatomic, retain) CommentsTableViewController *commentsController;
@end
