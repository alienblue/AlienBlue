#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RedditAPI.h"
#import "BrowserViewController.h"
#import	"CommentsTableViewController.h"
#import "PostsTableControllerView.h"
#import <StoreKit/StoreKit.h>
#import "MKStoreManager.h"

@interface NavigationController : UITabBarController <UITabBarControllerDelegate, UINavigationControllerDelegate, UIAccelerometerDelegate> 
{
//	NSString * postId;
//	NSString * browserURL;
	BOOL forcePortrait;
	BOOL shouldRefreshComments;
	BOOL shouldRefreshMessages;
	IBOutlet UINavigationController * postsNavigation;
	CommentsTableViewController * commentsView;
	BrowserViewController * browserView;
	NSMutableDictionary * post;
	NSTimer * statusNotifyTimer;
	RedditAPI * redAPI;
	NSUserDefaults * prefs;
	float tiltCalibration;
	BOOL tiltCalibrationModeActive;
	UISegmentedControl * votingSegment;
	IBOutlet UIView *proFeaturesSplash;
	NSString * replyCommentID;	
	BOOL isFullscreen;
	UIButton * exitFullscreenButton;	
	UIButton * backFullscreenButton;	
}

//@property (nonatomic, retain) NSString * postId;
@property (nonatomic) BOOL forcePortrait;
@property (assign) NSMutableDictionary * post;
@property BOOL shouldRefreshComments;
@property BOOL shouldRefreshMessages;
@property BOOL isFullscreen;
@property float tiltCalibration;
@property (assign) CommentsTableViewController * commentsView;
@property (assign) BrowserViewController * browserView;
@property (nonatomic, retain) IBOutlet UINavigationController * postsNavigation;
@property (nonatomic, copy) NSString *replyCommentID;
//@property (nonatomic, retain) NSString * browserURL;

-(void) loadNibs;
-(void) loadCommentsForPost:(NSMutableDictionary *) post;
-(void) browseToLinkFromComment:(NSString *) link;
-(void) browseToLinkFromPost:(NSMutableDictionary *) post;
-(void) browseToLinkFromMessage:(NSMutableDictionary *) link;
-(void) browse;
- (IBAction)voteSegmentChanged:(id)sender;
- (void) upvoteItem:(NSMutableDictionary *) item;
- (void) downvoteItem:(NSMutableDictionary *) item;
- (void) replyToItem:(NSMutableDictionary *) item;
- (void) clearAndRefreshPosts;
- (void) redrawFrames;
- (void) activateTiltCalibrationMode;
- (void) browseToPostThreadFromMessage:(NSMutableDictionary *) npost;
- (void) refreshVotingSegment;
- (void) drawFullScreenBackButton;
@end
