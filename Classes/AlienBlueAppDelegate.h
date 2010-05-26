//
//  AlienBlueAppDelegate.h
//  Alien Blue
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright The Design Shed 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditAPI.h"
#import "NavigationController.h"

@interface AlienBlueAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    IBOutlet NavigationController *tabBarController;
	RedditAPI * redditAPI;	
	NSTimer * inboxCheckTimer;
	NSUserDefaults * prefs;
	UIImageView * errorImage;
	IBOutlet UIImageView * blackBG;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NavigationController *tabBarController;
@property (nonatomic, retain) IBOutlet UIImageView *blackBG;
@property (readwrite, retain) RedditAPI *redditAPI;
- (void) refreshUnreadMailBadge;
-(IBAction) checkForNewMessages: (id) sender;
- (void) proVersionUpgraded;

- (void) showConnectionErrorImage;
- (void) hideConnectionErrorImage;
- (void) refreshBackground;
- (void) stopPurchaseIndicator;
@end
