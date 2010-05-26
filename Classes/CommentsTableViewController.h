//
//  CommentsTableViewController.h
//  Alien Blue
//
//  Created by Jason Morrissey on 29/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSON.h"
#import "CommentCell.h"
#import "RedditAPI.h"

@interface CommentsTableViewController : UITableViewController <UITextViewDelegate, UIActionSheetDelegate>{

	RedditAPI * redAPI;
	NSMutableArray * comments;
	NSMutableArray * bodyHeightCache;	
	NSTimer * progressTimer;
	NSMutableArray	*allLinks;
//	int link_counter;
	
	NSMutableArray	*flatComments;	// Search friendly list
//	NSMutableArray	*filteredListContent;	// The content filtered as a result of a search.	
	
	NSMutableDictionary	*linkImageDownloadQueue;
	NSMutableDictionary * post;
	
	int selected_row;
	int editing_row;
	
	// The saved state of the search UI if a memory warning removed the view.
    NSString		*savedSearchTerm;
    NSInteger		savedScopeButtonIndex;
    BOOL			searchWasActive;
	UIImage * button_background;
	UIImage * voteUpIcon;
	UIImage * voteDownIcon;
	UIImage * voteUpSelectedIcon;
	UIImage * voteDownSelectedIcon;
	
	NSUserDefaults * prefs;	
	CFTimeInterval stime;
	CFTimeInterval etime;
}

@property (nonatomic, retain) NSMutableArray *flatComments;
//@property (nonatomic, retain) NSMutableArray *filteredListContent;
@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;

- (NSMutableDictionary *) reformat:(NSMutableDictionary *) comment;
- (void) loadComments;
- (void) loadTestComments;
- (void) afterCommentReply:(NSString *) commentID;
- (void) toggleComment:(NSMutableDictionary *) comment;
- (void) contextForComment:(NSMutableDictionary *) comment;
- (void) voteUpComment:(NSMutableDictionary *) comment;
- (void) voteDownComment:(NSMutableDictionary *) comment;
- (void) showReplyAreaForComment:(NSMutableDictionary *) comment;
- (void) editModeForComment:(NSMutableDictionary *) comment;

- (void) toggleSavePost:(NSMutableDictionary *) ps;
- (void) toggleHidePost:(NSMutableDictionary *) ps;
- (void) selectComment:(NSMutableDictionary *) comment;
- (void) collapseToRootForComment:(NSMutableDictionary *) comment;
- (int) getCommentRowByName:(NSString *) cname;
- (IBAction)moreButtonClicked:(id)sender;
- (NSMutableDictionary *) getCommentById:(NSString *) cId;
@end
