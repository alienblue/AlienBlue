//
//  CommentCell.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 29/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "CommentCell.h"

@implementation CommentCell

@synthesize commentCellView;

//@synthesize body;
//@synthesize score;
//@synthesize author;
//@synthesize numReplies;
//@synthesize viewForBackground;
//@synthesize datetime;
//@synthesize buttonToolbar;
//@synthesize viewForTopBar;
//@synthesize topBarButton;
//@synthesize linkButtonTemplate;
//@synthesize viewForCommentOptions;
//@synthesize viewForCommentReply;
//@synthesize parentButton;
//@synthesize voteUpButton;
//@synthesize voteDownButton;
//@synthesize showReplyAreaButton;
//@synthesize submitReply;
//@synthesize cancelReply;
//@synthesize replyTextView;
//@synthesize levelArrows;
//@synthesize editButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
		
		CGRect cellViewFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		commentCellView = [[CommentCellView alloc] initWithFrame:cellViewFrame];
		commentCellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:commentCellView];
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

- (void)setCommentWrapper:(CommentWrapper *)commentWrap
{
	[commentCellView setCommentWrapper:commentWrap];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}

- (void)redisplay {
	[commentCellView setNeedsDisplay];
}

@end
