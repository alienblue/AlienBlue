//
//  MessagesTableViewController.h
//  Alien Blue
//
//  Created by Jason Morrissey on 16/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditAPI.h"
#import "MessageCell.h"

@interface MessagesTableViewController : UITableViewController <UITextViewDelegate> {
	NSMutableArray * messages;
	RedditAPI * redAPI;
	NSTimer * checkInboxTimer;
	NSTimer * progressTimer;
	float ProgressValue;
	NSUserDefaults * prefs;	
	BOOL resultsFetched;
}
- (IBAction) fetchMessages:(id)sender;
@end
