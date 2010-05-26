//
//  CommentCell.h
//  Alien Blue
//
//  Created by Jason Morrissey on 29/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentCellView.h"

@interface CommentCell : UITableViewCell {
	
	CommentCellView *commentCellView;
	
//	IBOutlet UITextView *body;
//	IBOutlet UILabel *score;
//	IBOutlet UILabel *author;
//	IBOutlet UILabel *numReplies;	
//	IBOutlet UILabel *datetime;	
//	IBOutlet UIView *viewForBackground;
//	IBOutlet UIView *viewForTopBar;
//	IBOutlet UIView *viewForCommentOptions;
//	IBOutlet UIView *viewForCommentReply;
//	IBOutlet UIImageView *levelArrows;
//	
//	IBOutlet UIButton *topBarButton;
//	IBOutlet UIButton *linkButtonTemplate;
//	IBOutlet UIToolbar *buttonToolbar;
//	
//	IBOutlet UIButton *editButton;
//	IBOutlet UIButton *parentButton;
//	IBOutlet UIButton *voteUpButton;
//	IBOutlet UIButton *voteDownButton;
//	IBOutlet UIButton *showReplyAreaButton;
//	IBOutlet UIButton *submitReply;
//	IBOutlet UIButton *cancelReply;
//	IBOutlet UITextView *replyTextView;
//	
//	BOOL collapsed;
}

//@property (nonatomic, retain) IBOutlet  UITextView *body;	
//@property (nonatomic, retain) IBOutlet  UILabel *numReplies;	
//@property (nonatomic, retain) IBOutlet  UILabel *score;	
//@property (nonatomic, retain) IBOutlet  UILabel *author;
//@property (nonatomic, retain) IBOutlet  UILabel *datetime;
//@property (nonatomic, retain) IBOutlet  UIView *viewForBackground;
//@property (nonatomic, retain) IBOutlet  UIView *viewForTopBar;
//@property (nonatomic, retain) IBOutlet  UIView *viewForCommentOptions;
//@property (nonatomic, retain) IBOutlet  UIView *viewForCommentReply;
//@property (nonatomic, retain) IBOutlet  UIImageView *levelArrows;
//
//@property (nonatomic, retain) IBOutlet  UIToolbar *buttonToolbar;
//@property (nonatomic, retain) IBOutlet  UIButton *topBarButton;
//@property (nonatomic, retain) IBOutlet  UIButton *linkButtonTemplate;
//
//@property (nonatomic, retain) IBOutlet  UIButton *editButton;
//@property (nonatomic, retain) IBOutlet  UIButton *parentButton;
//@property (nonatomic, retain) IBOutlet  UIButton *voteUpButton;
//@property (nonatomic, retain) IBOutlet  UIButton *voteDownButton;
//@property (nonatomic, retain) IBOutlet  UIButton *showReplyAreaButton;
//@property (nonatomic, retain) IBOutlet  UIButton *submitReply;
//@property (nonatomic, retain) IBOutlet  UIButton *cancelReply;
//@property (nonatomic, retain) IBOutlet  UITextView *replyTextView;

@property (nonatomic, retain) CommentCellView *commentCellView;

- (void)setCommentWrapper:(CommentWrapper *)commentWrap;
- (void)redisplay;

@end
