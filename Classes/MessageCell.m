//
//  MessageCell.m
//  Alien Blue
//
//  Created by Jason Morrissey on 16/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "MessageCell.h"


@implementation MessageCell

@synthesize body;
@synthesize author;
@synthesize datetime;	
@synthesize viewForMessageReply;
@synthesize showReplyAreaButton;
@synthesize submitReply;
@synthesize cancelReply;
@synthesize replyTextView;
@synthesize showContextButton;



- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


@end
