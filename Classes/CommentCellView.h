//
//  CommentCellView.h
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 23/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentWrapper.h"

@interface CommentCellView : UIView {

	CommentWrapper *commentWrapper;
	UITextView * replyTextView;
	CGPoint gestureStartPoint;
}

@property (nonatomic, retain) CommentWrapper *commentWrapper;
@property (nonatomic, retain) UITextView *replyTextView;

- (void)drawLinkButtons;

@end
