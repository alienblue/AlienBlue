//
//  FirstViewController.m
//  Alien Blue
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright The Design Shed 2010. All rights reserved.
//

#import "BrowserViewController.h"
#import "NavigationController.h"

@implementation BrowserViewController

@synthesize webView, navTitle, readabilityButton, loadingIndicator, navbar, backButton, backTo;

-(void) browseImage:(NSString *) link
{
	NSString *htmlString = @"<html><body bgcolor=\"040911\"><img src='%@' width='900'></body></html>";
	NSString *imageHTML  = [[NSString alloc] initWithFormat:htmlString, link];
	webView.scalesPageToFit = YES;
	[webView loadHTMLString:imageHTML baseURL:nil];

}

-(void) browseArticle:(NSString *) address
{
	NSLog(@"browseTo : %@", address);
	NSURL *url = [NSURL URLWithString:address];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[webView setBackgroundColor:[UIColor blackColor]];
	[webView loadRequest:requestObj];
	readability_refresh	= FALSE;
}

- (BOOL) isImageLink:(NSString *) link
{
	if(
	   [link rangeOfString:@".png" options:NSCaseInsensitiveSearch].location != NSNotFound	||
	   [link rangeOfString:@".jpg" options:NSCaseInsensitiveSearch].location != NSNotFound	||
	   [link rangeOfString:@".jpeg" options:NSCaseInsensitiveSearch].location != NSNotFound
	   )
		return YES;
	else
		return NO;
}


- (IBAction)gotoMessages:(id)sender
{
	NSLog(@"gotoMessages in()");
	//	[self.navigationController popViewControllerAnimated:YES];
	NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
	[[nc postsNavigation] popViewControllerAnimated:NO];
	[nc setSelectedIndex:1];
}



-(void) browseToLink:(NSString *) link fromMessages:(BOOL) fromMessages
{
	if (fromMessages)
	{
//		NavigationController * nc = (NavigationController *) [[self parentViewController] parentViewController];
		self.navigationItem.titleView = nil;
//
//		UIBarButtonItem * back = self.navigationItem.leftBarButtonItem;
//		[back setTitle:@"Messages"];
//		[back setTarget:self];
//		[back setAction:@selector(gotoMessages:)];
	}
	else
	{
//		self.navigationItem.leftBarButtonItem = nil;
//		[[self navigationItem] setHidesBackButton:NO];
	}
	
	if ([self isImageLink:link])
	{
		[self browseImage:link];
	}
	else
		[self browseArticle:link];
}

- (IBAction)goBack:(id)sender
{
	NavigationController * nc = (NavigationController *) [self parentViewController];
	if ([backTo isEqualToString:@"Comments"])
		[nc setSelectedViewController:[[nc viewControllers] objectAtIndex:1]];
	else
		[nc setSelectedViewController:[[nc viewControllers] objectAtIndex:0]];		
}

- (IBAction)readability:(id)sender
{
	if ([readabilityButton image] == readabilityIcon)
	{
		NSLog(@"readability mode");
		NSString * rdb = @"javascript:(function(){readStyle='style-apertura';readSize='size-x-large';readMargin='margin-wide';_readability_script=document.createElement('SCRIPT');_readability_script.type='text/javascript';_readability_script.src='http://lab.arc90.com/experiments/readability/js/readability.js?x='+(Math.random());document.getElementsByTagName('head')[0].appendChild(_readability_script);_readability_css=document.createElement('LINK');_readability_css.rel='stylesheet';_readability_css.href='http://lab.arc90.com/experiments/readability/css/readability.css';_readability_css.type='text/css';_readability_css.media='all';document.getElementsByTagName('head')[0].appendChild(_readability_css);_readability_print_css=document.createElement('LINK');_readability_print_css.rel='stylesheet';_readability_print_css.href='http://lab.arc90.com/experiments/readability/css/readability-print.css';_readability_print_css.media='print';_readability_print_css.type='text/css';document.getElementsByTagName('head')[0].appendChild(_readability_print_css);})();";
		[self.webView stringByEvaluatingJavaScriptFromString:rdb];
		[readabilityButton setImage:readabilityBackIcon];
//		[readabilityButton setTitle:@"Original"];
		readability_refresh = FALSE;
	}
	else
	{
		NSLog(@"original view");
		[loadingIndicator startAnimating];
		NSString * rdb = @"javascript:window.location.reload();";
		[self.webView stringByEvaluatingJavaScriptFromString:rdb];
		[readabilityButton setImage:readabilityIcon];		
//		[readabilityButton setTitle:@"Readability"];
//		readability_refresh = TRUE;
	}
}

- (IBAction)normal:(id)sender
{
	NSLog(@"normal mode");
	[self.webView goBack];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[loadingIndicator stopAnimating];
	[readabilityButton setEnabled:TRUE];
	
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	NSLog(@"loading web page ...");
	[loadingIndicator startAnimating];
	if (!readability_refresh)
	{
		[readabilityButton setImage:readabilityIcon];
	}
	else
	{
		[readabilityButton setEnabled:FALSE];
		readability_refresh = FALSE;	
	}
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	prefs = [NSUserDefaults standardUserDefaults];	
	[loadingIndicator stopAnimating];

//	readabilityIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"readability-icon" ofType:@"png"]];	
//	readabilityBackIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"readability-back-icon" ofType:@"png"]];

	readabilityIcon = [[UIImage imageNamed:@"readability-icon.png"] retain];
	readabilityBackIcon = [[UIImage imageNamed:@"readability-back-icon.png"] retain];
	
	readabilityButton = [[UIBarButtonItem alloc] initWithImage:readabilityIcon style:UIBarButtonItemStyleBordered target:self action:@selector(readability:)];
	[readabilityButton setStyle:UIBarButtonItemStyleBordered];
//	readabilityButton = [[UIBarButtonItem alloc] initWithTitle:@"Readability" style:UIBarButtonItemStyleBordered target:self action:@selector(readability:)];
	[readabilityButton setEnabled:FALSE];
	self.navigationItem.rightBarButtonItem = readabilityButton;
	
	// create a very dark blue background for the Webview, otherwise we risk exploding
	// the user's retina if they're browsing at night.
	NSString *htmlString = @"<html><body bgcolor=\"040911\"></body></html>";
	[webView loadHTMLString:htmlString baseURL:nil];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
	// if the user hits back to comments/posts on the top nav, there's no point using
	// up their bandwidth unnecessarily.
	[webView stopLoading];
}


- (void)dealloc {

    [super dealloc];
}

@end
