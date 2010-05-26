//
//  MessageCell.h
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 16/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MessageCell : UITableViewCell {
	IBOutlet UITextView *body;
	IBOutlet UILabel *author;
	IBOutlet UILabel *datetime;	
	IBOutlet UIView *viewForMessageReply;
	IBOutlet UIButton *showReplyAreaButton;
	IBOutlet UIButton *showContextButton;
	IBOutlet UIButton *submitReply;
	IBOutlet UIButton *cancelReply;
	IBOutlet UITextView *replyTextView;
}


@property (nonatomic, retain) IBOutlet  UITextView *body;	
@property (nonatomic, retain) IBOutlet  UILabel *author;
@property (nonatomic, retain) IBOutlet  UILabel *datetime;
@property (nonatomic, retain) IBOutlet  UIView *viewForMessageReply;
@property (nonatomic, retain) IBOutlet  UIButton *showReplyAreaButton;
@property (nonatomic, retain) IBOutlet  UIButton *submitReply;
@property (nonatomic, retain) IBOutlet  UIButton *showContextButton;
@property (nonatomic, retain) IBOutlet  UIButton *cancelReply;
@property (nonatomic, retain) IBOutlet  UITextView *replyTextView;

@end
