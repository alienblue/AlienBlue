//
//  FirstViewController.h
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright The Design Shed 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BrowserViewController : UIViewController {
	BOOL readability_refresh;

	IBOutlet UIWebView *webView;
	IBOutlet UINavigationItem *navTitle;
	IBOutlet UINavigationBar *navbar;
	IBOutlet UIBarButtonItem *backButton;
	IBOutlet UIActivityIndicatorView *loadingIndicator;	
	UIBarButtonItem * readabilityButton;	
	NSString * backTo;
	NSUserDefaults * prefs;
	UIImage * readabilityIcon;
	UIImage * readabilityBackIcon;
}

@property (nonatomic, retain) IBOutlet  UIWebView *webView;
@property (nonatomic, retain) IBOutlet  UINavigationBar *navbar;
@property (nonatomic, retain) IBOutlet  UINavigationItem *navTitle;
@property (nonatomic, retain) IBOutlet  UIBarButtonItem *readabilityButton;
@property (nonatomic, retain) IBOutlet  UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet  UIActivityIndicatorView *loadingIndicator;
@property (retain) NSString * backTo;

- (IBAction)goBack:(id)sender;
- (IBAction)readability:(id)sender;
-(void) browseToLink:(NSString *) link fromMessages:(BOOL) fromMessages;

@end
