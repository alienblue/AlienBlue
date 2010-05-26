//
//  RedditAPI.h
//  Alien Blue
//
//  Created by Jason Morrissey on 4/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"

@interface RedditAPI : NSObject {
	NSString * modhash;
	NSString * cookie;
	NSMutableDictionary * connections;
	NSMutableArray * hideQueue;
	NSString * authenticatedUser;
	
	id loginResultCallBackTarget;
	id postFetchResultCallBackTarget;
	id commentFetchResultCallBackTarget;
	id subredditListCallBackTarget;
	id inboxCallBackTarget;
	id unreadMessageCountCallBackTarget;
	id runAfterLoginTarget;
	id replyResultCallBackTarget;
	
	NSString * runAfterLoginMethod;

	id runAfterInboxCheckTarget;
	NSString * runAfterInboxCheckMethod;

	BOOL authenticated;
	int unreadMessageCount;
	BOOL loadingPosts;
	BOOL loadingMessages;
	NSUserDefaults * prefs;
}

@property (retain) NSString * modhash;
@property (retain) NSString * cookie;
@property (retain) NSString * authenticatedUser;
@property BOOL authenticated;
@property BOOL loadingPosts;
@property BOOL loadingMessages;
@property int unreadMessageCount;

- (void) loginUser:(NSString *) username withPassword:(NSString *) password callBackTarget:(id) target;

- (void) fetchPostsForSubreddit:(NSString *)subreddit afterPostID:(NSString *) postID callBackTarget:(id) target;
- (void) fetchCommentsForPostID:(NSString *) postID callBackTarget:(id) target;

- (void) fetchMessageInboxAfterMessageID:(NSString *) messageID withCallBackTarget:(id) target;
- (void) authenticateWithCallbackTarget:(id) target andCallBackAction:(NSString *) method;

- (int) hideQueueLength;
- (void) processFirstInPostQueue;
- (BOOL) isPostInHideQueue:(NSString *) postID;
- (void) addPostToHideQueue:(NSString *) postID;
- (void) hidePostWithID: (NSString *) postID;
- (void) savePostWithID: (NSString *) postID;
- (void) unsavePostWithID: (NSString *) postID;
- (void) fetchUnreadMessageCount:(id) target;
- (void) submitVote: (NSMutableDictionary *) item;
- (void) submitReply: (NSMutableDictionary *) item withCallBackTarget:(id) target;
- (void) showAuthorisationRequiredDialog;
- (void) fetchSubscribedRedditsWithCallBackTarget:(id) target;
- (void) submitChangeReply: (NSMutableDictionary *) item withCallBackTarget:(id) target;
- (void) unhidePostWithID: (NSString *) postID;
- (void) unhideResponseReceived:(id) sender;
- (void) testReachability;

+ (BOOL) isImageLink:(NSString *) link;
+ (BOOL) isVideoLink:(NSString *) link;
+ (BOOL) isSelfLink:(NSString *) link;
+ (NSString *) getLinkType:(NSString *) url;
+ (NSString *) fixImgurLink:(NSString *) link;
+ (NSString *) useLowResImgurVersion:(NSString *) link;

@end
