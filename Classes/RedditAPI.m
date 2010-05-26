//
//  RedditAPI.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 4/04/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "RedditAPI.h"
#import "Reachability.h"
#import "AlienBlueAppDelegate.h"

@implementation RedditAPI

@synthesize modhash;
@synthesize cookie;
@synthesize authenticated;
@synthesize unreadMessageCount;
@synthesize authenticatedUser;
@synthesize loadingPosts;
@synthesize loadingMessages;

//NSString * server = @"http://10.1.1.2:8080";
//NSString * cookieDomain = @"10.1.1.2";

NSString * server = @"http://www.reddit.com";
NSString * cookieDomain = @".reddit.com";

- (id) init
{
	self = [super init];
	if (self != nil) {
		NSLog(@"initialising RedditAPI");
		authenticatedUser = @"";
		loadingPosts = NO;
		loadingMessages = NO;
		unreadMessageCount = 0;
		connections = [[NSMutableDictionary alloc] init];
		hideQueue = [[NSMutableArray alloc] init];		
		prefs = [NSUserDefaults standardUserDefaults];
		if([prefs objectForKey:@"modhash"])
			modhash = [prefs objectForKey:@"modhash"];
		else
			modhash = @"";
		if([prefs objectForKey:@"cookie"])
			cookie = [prefs objectForKey:@"cookie"];
		else
			cookie = @"";
		NSLog(@"modhash: %@", modhash);
		NSLog(@"cookie: %@", cookie);
		if([prefs objectForKey:@"username"])
		{
			NSLog(@"username:%@", [prefs objectForKey:@"username"]);
			authenticatedUser = [[prefs objectForKey:@"username"] copy];
		}
		authenticated = NO;
	}
	return self;
}

- (int) hideQueueLength
{
	return [hideQueue count];
}

- (void) processFirstInPostQueue
{
	if ([self hideQueueLength] > 0)
	{
		NSLog(@"-- hiding post : %@", [hideQueue objectAtIndex:0]);
		[self hidePostWithID:[hideQueue objectAtIndex:0]];
		[hideQueue removeObjectAtIndex:0];
	}
}


- (void) showAuthorisationRequiredDialog
{
	NSLog(@"-- unauthorised --");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please login." message:@"You need to enter your Reddit username and password in the 'Settings' panel." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];
	[alert release];	
}


- (BOOL) isPostInHideQueue:(NSString *) postID
{
	return [hideQueue containsObject:postID];
}

- (void) addPostToHideQueue:(NSString *) postID
{
	if (![self isPostInHideQueue:postID])
		[hideQueue addObject:postID];
}


// here is the flow for authentication
// 1. check inbox
// if not authorised, then 2. login.
// this is the order that methods are called in this process:
// authenticate => fetchfetchMessageInboxWithCallBackTarget
// => apiUnreadMessageCountResponse => authenticateStage2 =>
// (if necessary) loginUser => apiLoginResponse => callbacks
// by the end of this process, the authenticated variable will
// be set to YES if the user is authorised.

- (void) authenticateWithCallbackTarget:(id) target andCallBackAction:(NSString *) method
{
	NSLog(@"authenticate stage 1 in()");
	runAfterLoginTarget = target;
	runAfterLoginMethod = method;

	// Only bother with all of this authentication stuff if the user has already entered a
	// username and password (otherwise we can assume it is an unregistered user).
	if ([prefs objectForKey:@"username"] && [prefs objectForKey:@"password"]
		&& [[prefs objectForKey:@"username"] length] > 0 && [[prefs objectForKey:@"password"] length] > 0)
	{
		// first try to hit the inbox and see if we're authenticated
		runAfterInboxCheckTarget = self;
		runAfterInboxCheckMethod = @"authenticateStage2:";
		[self fetchUnreadMessageCount:self];
//		[self fetchMessageInboxAfterMessageID:@"" withCallBackTarget:self];
	}
	else
	{
		// assume unregistered user and run callbacks
		if (runAfterLoginTarget)
		{
			SEL action = NSSelectorFromString(runAfterLoginMethod);
			[runAfterLoginTarget performSelector:action withObject:nil];
		}
	}
}

// used for stage 1 of authentication :: check inbox to see if we're authenticated.
- (void) apiUnreadMessageCountResponse:(id)sender
{

	NSLog(@"RedditAPI :: apiUnreadMessageCountResponse");
	if (runAfterInboxCheckTarget)
	{
		SEL action = NSSelectorFromString(runAfterInboxCheckMethod);
		[runAfterInboxCheckTarget performSelector:action withObject:nil];
	}	
}

- (void) authenticateStage2:(id)sender
{
	NSLog(@"authenticate stage 2 in()");
	// the inbox check says that we're still unauthenticated
	if (!authenticated)
	{
		[self loginUser:[prefs objectForKey:@"username"] withPassword:[prefs objectForKey:@"password"] callBackTarget:self];
	}
	else
	{
	// assume we are logged in, so time to run callbacks:
		if (runAfterLoginTarget)
		{
			SEL action = NSSelectorFromString(runAfterLoginMethod);
			[runAfterLoginTarget performSelector:action withObject:nil];
		}			
	}
}

// used for stage2 of authentication (when username and password response returns)
- (void) apiLoginResponse:(id)sender 
{
	NSLog(@"RedditAPI :: apiLoginResponse");
	if (runAfterLoginTarget)
	{
		SEL action = NSSelectorFromString(runAfterLoginMethod);
		[runAfterLoginTarget performSelector:action withObject:nil];
	}	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//	NSLog(@"RedditAPI::connection:didReceiveResponse in()");
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
//	NSLog(connectionKey);
	NSMutableDictionary * dl = [connections objectForKey:connectionKey];
	NSMutableData *data = [[NSMutableData alloc] init];
//	NSMutableData * data = [NSMutableData dataWithLength:0];
	[dl setObject:data forKey:@"data"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//	NSLog(@"RedditAPI::connection:didReceiveData in()"); 	
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * dl = [connections objectForKey:connectionKey];
	NSMutableData * oldData = (NSMutableData *) [dl objectForKey:@"data"];
	[oldData appendData:data];
//	NSLog(@"Data Length : %d", [oldData length]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"RedditAPI::connection:DidFailWithError in()"); 
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * dl = [connections objectForKey:connectionKey];
	// perform necessary callbacks with the data.
	if ([dl objectForKey:@"failedNotifyAction"] && [dl objectForKey:@"afterCompleteTarget"])
	{
		SEL action = NSSelectorFromString([dl valueForKey:@"failedNotifyAction"]);
		[[dl objectForKey:@"afterCompleteTarget"] performSelector:action];
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] hideConnectionErrorImage];	
	NSLog(@"RedditAPI::connection:DidFinishLoading in()");
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * dl = [connections objectForKey:connectionKey];

	// perform necessary callbacks with the data.
	if ([dl objectForKey:@"afterCompleteAction"] && [dl objectForKey:@"afterCompleteTarget"])
	{
		SEL action = NSSelectorFromString([dl valueForKey:@"afterCompleteAction"]);
		[[dl objectForKey:@"afterCompleteTarget"] performSelector:action withObject:[dl objectForKey:@"data"]];
	}
	[connections removeObjectForKey:connectionKey];
	[dl release];
}



- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
//	NSLog(@"RedditAPI :: connection request");	
    return request;
}

- (IBAction)testFunction:(id)sender 
{
	NSLog(@"testFunction in()");
	NSData * data = (NSData *) sender;
	NSLog(@"Data Length : %d", [data length]);
}

- (void) testReachability
{
	Reachability * r = [Reachability reachabilityWithHostName:server];
	
	NetworkStatus internetStatus = [r currentReachabilityStatus];
	
	if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN))
	{
		[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] showConnectionErrorImage];
//		[self connectionFailedDialog:nil];
	}
}


- (IBAction)connectionFailedDialog:(id)sender 
{
	NSLog(@"connection failed dialog in()");
	loadingPosts = NO;
	loadingMessages = NO;
	[hideQueue removeAllObjects];
	
//	[[[UIApplication sharedApplication] delegate] showConnectionErrorImage];
	
	// release connections so that we don't keep bugging the user if there are multiple
	// connections.
	[connections removeAllObjects];
}

- (void) doPostToURL:(NSString *) urlstring 
					withParams:(NSString *) params 
					callBackTarget:(id) target
					callBackMethod:(NSString *) method
					failedMethod:(NSString *) method_failed
{
	NSData *postData = [params dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:urlstring]];
	if (cookie && [cookie length] > 0)
	{
		NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
									cookieDomain, NSHTTPCookieDomain,
									@"/", NSHTTPCookiePath,  // IMPORTANT!
									@"reddit_session", NSHTTPCookieName,
									cookie, NSHTTPCookieValue,									
									nil];
		NSHTTPCookie *http_cookie = [NSHTTPCookie cookieWithProperties:properties];
		NSArray* cookies = [NSArray arrayWithObjects: http_cookie, nil];
		NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
		[request setAllHTTPHeaderFields:headers];
	}
	
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	
//	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary *dl = [[NSMutableDictionary alloc] init];
	[dl setValue:connectionKey forKey:@"connectionKey"];
	[dl setValue:target forKey:@"afterCompleteTarget"];
	[dl setValue:method forKey:@"afterCompleteAction"];
	[dl setValue:method_failed forKey:@"failedNotifyAction"];
	[connections setValue:dl forKey:connectionKey];
//	[connection release];
	[urlstring release];	
}

- (void) doGetURL:(NSString *) urlstring 
	  callBackTarget:(id) target
	  callBackMethod:(NSString *) method
		failedMethod:(NSString *) method_failed
{

	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:urlstring]];
	NSLog(@"-- get URL with cookie : [%@]", [self cookie]);
	if (cookie && [cookie length] > 0)
	{
		NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
									cookieDomain, NSHTTPCookieDomain,
									@"/", NSHTTPCookiePath,  // IMPORTANT!
									@"reddit_session", NSHTTPCookieName,
									cookie, NSHTTPCookieValue,									
//									[cookie stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], NSHTTPCookieValue,
									nil];
		NSHTTPCookie *http_cookie = [NSHTTPCookie cookieWithProperties:properties];
		NSArray* cookies = [NSArray arrayWithObjects: http_cookie, nil];
		NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
		[request setAllHTTPHeaderFields:headers];
	}
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
//	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary *dl = [[NSMutableDictionary alloc] init];
	
	[dl setValue:connectionKey forKey:@"connectionKey"];
	if (target && method)
	{
		[dl setValue:target forKey:@"afterCompleteTarget"];
		[dl setValue:method forKey:@"afterCompleteAction"];
	}
	[dl setValue:method_failed forKey:@"failedNotifyAction"];
	[connections setValue:dl forKey:connectionKey];
//	[connection release];
	[urlstring release];
}


- (void) loginUser:(NSString *) username withPassword:(NSString *) password callBackTarget:(id) target
{
	loginResultCallBackTarget = target;
	NSLog(@"login in (%@ : %@)", username, password);
	NSString * login_url = [[NSString alloc] initWithFormat:@"%@/api/login/%@",server, username];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&user=%@&passwd=%@",username, password];
	NSLog(params);
	
	[self doPostToURL:login_url	withParams:params callBackTarget:self callBackMethod:@"loginUserResponse:" failedMethod:@"connectionFailedDialog:"];
}

- (void) unhideResponseReceived:(id) sender
{
	NSLog(@"-- unhide response received --");
	NSData * data = (NSData *) sender;
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(responseString);
	[data release];
}

- (void) hideResponseReceived:(id) sender
{
	NSLog(@"-- hide response received --");
	NSData * data = (NSData *) sender;
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(responseString);
	[data release];	
}

- (void) saveResponseReceived:(id) sender
{
	NSLog(@"-- save response received --");
	NSData * data = (NSData *) sender;
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(responseString);
	[data release];	
}

- (void) unsaveResponseReceived:(id) sender
{
	NSLog(@"-- unsave response received --");
	NSData * data = (NSData *) sender;
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(responseString);
	[data release];	
}



- (void) unsavePostWithID: (NSString *) postID
{
	NSLog(@"-- unsaving post with id (%@)", postID);
	NSString * unsave_url = [[NSString alloc] initWithFormat:@"%@/api/unsave",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&executed=unsaved&id=%@&uh=%@",postID, modhash];
	NSLog(params);
	[self doPostToURL:unsave_url withParams:params callBackTarget:self callBackMethod:@"unsaveResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}


- (void) savePostWithID: (NSString *) postID
{
	NSLog(@"-- saving post with id (%@)", postID);
	NSString * save_url = [[NSString alloc] initWithFormat:@"%@/api/save",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&executed=saved&id=%@&uh=%@",postID, modhash];
	NSLog(params);
	[self doPostToURL:save_url withParams:params callBackTarget:self callBackMethod:@"saveResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}

- (void) unhidePostWithID: (NSString *) postID
{
	NSLog(@"-- un-hiding post with id (%@)", postID);
	NSString * hide_url = [[NSString alloc] initWithFormat:@"%@/api/unhide",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&executed=unhidden&id=%@&uh=%@",postID, modhash];
	NSLog(params);
	[self doPostToURL:hide_url withParams:params callBackTarget:self callBackMethod:@"unhideResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}

- (void) hidePostWithID: (NSString *) postID
{
	NSLog(@"-- hiding post with id (%@)", postID);
	NSString * hide_url = [[NSString alloc] initWithFormat:@"%@/api/hide",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&executed=hidden&id=%@&uh=%@",postID, modhash];
	NSLog(params);
	[self doPostToURL:hide_url withParams:params callBackTarget:self callBackMethod:@"hideResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}

- (void) voteResponseReceived:(id) sender
{
	NSLog(@"-- vote response received --");
	NSData * data = (NSData *) sender;
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(responseString);
	[data release];
}

- (void) submitVote: (NSMutableDictionary *) item
{
	NSString * itemID = [item valueForKey:@"name"];
	int voteDirection = [[item valueForKey:@"voteDirection"] intValue];
	NSLog(@"-- submitting vote (%d) for item with id (%@)", voteDirection, itemID);
	NSString * hide_url = [[NSString alloc] initWithFormat:@"%@/api/vote",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&dir=%d&id=%@&uh=%@",voteDirection,itemID, modhash];
	NSLog(params);
	[self doPostToURL:hide_url withParams:params callBackTarget:self callBackMethod:@"voteResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}

- (void) replyResponseReceived:(id) sender
{
	NSLog(@"-- reply/change response received --");
	SBJSON *parser = [[SBJSON alloc] init];
	NSData * data = (NSData *) sender;
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSDictionary * response = [[parser objectWithString:responseString error:nil] objectForKey:@"json"];
	NSString * newID = [[[[[response objectForKey:@"data"] objectForKey:@"things"] objectAtIndex:0] objectForKey:@"data"] valueForKey:@"id"];
	NSLog(@"newly created id: %@", newID);
	
//	NSLog(@"----------------");
//	NSLog(responseString);
//	NSLog(@"----------------");
	if (replyResultCallBackTarget)
	{
		SEL action = NSSelectorFromString(@"apiReplyResponse:");
		[replyResultCallBackTarget performSelector:action withObject:newID];
	}	
	
//	NSLog(responseString);
	[responseString release];
//	[response release];
	[data release];
	[parser release];	
}

- (void) submitChangeReply: (NSMutableDictionary *) item withCallBackTarget:(id) target;
{
	replyResultCallBackTarget = target;
	NSString * itemID = [item valueForKey:@"name"];
	NSString * replyText = [item valueForKey:@"replyText"];
	NSLog(@"-- changing reply (%@) for item with id (%@)", replyText, itemID);
	NSString * reply_url = [[NSString alloc] initWithFormat:@"%@/api/editusertext",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&text=%@&thing_id=%@&uh=%@", replyText, itemID, modhash];
	NSLog(reply_url);
	NSLog(params);	
	[self doPostToURL:reply_url withParams:params callBackTarget:self callBackMethod:@"replyResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}


- (void) submitReply: (NSMutableDictionary *) item withCallBackTarget:(id) target;
{
	replyResultCallBackTarget = target;
	NSString * itemID = [item valueForKey:@"name"];
	NSString * replyText = [item valueForKey:@"replyText"];
	NSLog(@"-- submitting reply (%@) for item with id (%@)", replyText, itemID);
	NSString * reply_url = [[NSString alloc] initWithFormat:@"%@/api/comment",server];
	NSString * params = [[NSString alloc] initWithFormat:@"api_type=json&text=%@&thing_id=%@&uh=%@", replyText, itemID, modhash];
	NSLog(reply_url);
	NSLog(params);	
	[self doPostToURL:reply_url withParams:params callBackTarget:self callBackMethod:@"replyResponseReceived:" failedMethod:@"connectionFailedDialog:"];
}


- (void) loginUserResponse:(id) sender
{
//	modhash = @"4wrjzavo86d94003784ca676bbd9f775ec5a01deb199aca959";


	NSLog(@"loginUserResponse in()");
	NSData * data = (NSData *) sender;
	SBJSON *parser = [[SBJSON alloc] init];
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	NSLog(responseString);
	NSDictionary *response = [[parser objectWithString:responseString error:nil] objectForKey:@"json"];
	if ([response objectForKey:@"data"])
	{
		NSDictionary * loginResult = [response objectForKey:@"data"];
		modhash = (NSString *) [[loginResult valueForKey:@"modhash"] copy];
		cookie = (NSString *) [[loginResult valueForKey:@"cookie"] copy];
		authenticated = YES;

		[prefs setObject:modhash forKey:@"modhash"];
		[prefs setObject:cookie forKey:@"cookie"];
		[prefs synchronize];
		authenticatedUser = [[prefs objectForKey:@"username"] copy];
		NSLog(@"modhash : %@", modhash);
		NSLog(@"cookie : %@", cookie);		
		
		if (loginResultCallBackTarget)
		{
			SEL action = NSSelectorFromString(@"apiLoginResponse:");
			[loginResultCallBackTarget performSelector:action withObject:modhash];
		}
//		[loginResult release];
	}
	else
	{
		modhash = @"";
		cookie = @"";
		[prefs setObject:modhash forKey:@"modhash"];
		[prefs setObject:cookie forKey:@"cookie"];
		[prefs synchronize];
		
		NSLog(@"login failed");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Please check your username and password in the Settings panel." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
		
	}
//	[response release];
	[responseString release];
	[data release];
	[parser release];	
}

- (void) fetchCommentsResponse:(id) sender
{
	NSLog(@"fetchCommentsResponse in()");
	NSData * data = (NSData *) sender;
	SBJSON *parser = [[SBJSON alloc] init];
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	
//	NSLog(@"-------------");
//	NSLog(responseString);
//	NSLog(@"-------------");
	id response = [parser objectWithString:responseString error:nil];
	if (commentFetchResultCallBackTarget)
	{
		SEL action = NSSelectorFromString(@"apiCommentsResponse:");
		[commentFetchResultCallBackTarget performSelector:action withObject:response];
	}
	[responseString release];
	[data release];
	[parser release];
}

- (void) fetchCommentsForPostID:(NSString *) postID callBackTarget:(id) target
{
	NSLog(@"fetchCommentsForPostID in()");
	NSString * fetch_comments_url = [[NSString alloc] initWithFormat:@"%@/comments/%@/.json?sort=top", server, postID];

	NSLog(fetch_comments_url);
	
	commentFetchResultCallBackTarget = target;
	
	[self doGetURL:fetch_comments_url callBackTarget:self callBackMethod:@"fetchCommentsResponse:" failedMethod:@"connectionFailedDialog:"];
}

- (void) fetchPostResponse:(id) sender
{
	NSLog(@"fetchPostResponse in()");
	NSData * data = (NSData *) sender;
	SBJSON *parser = [[SBJSON alloc] init];
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
//	NSLog(responseString);
	NSMutableDictionary *response = [parser objectWithString:responseString error:nil];
	[self setLoadingPosts:NO];
	if (postFetchResultCallBackTarget)
	{
		SEL action = NSSelectorFromString(@"apiPostsResponse:");
		[postFetchResultCallBackTarget performSelector:action withObject:response];
//		[postFetchResultCallBackTarget performSelectorOnMainThread:action withObject:response waitUntilDone:NO];
	}
	[data release];
	[responseString release];
	[parser release];	
}

- (void) fetchPostsForSubreddit:(NSString *)subreddit afterPostID:(NSString *) postID callBackTarget:(id) target
{
	NSLog(@"fetchPostsWithCount in() for subreddit: %@ after Post ID: %@", subreddit, postID);
	[self setLoadingPosts:YES];
	NSString * fetch_url;
	NSString * after_post_param;
	
	// we fetch a little extra if we are in the process of hiding posts
	// otherwise, when we filter out items that are currently in the hideQueue
	// the user will end up seeing only a few posts.
	// eg. retrieving 25 while still hiding 20 would otherwise show only 5 posts.
	int fetch_count = 25 + [self hideQueueLength];

	if (postID && [postID length] > 0)
		after_post_param = [NSString stringWithFormat:@"?limit=%d&after=%@", fetch_count, postID];
	else
		after_post_param = [NSString stringWithFormat:@"?limit=%d", fetch_count];		
	
	if ([subreddit length] > 0)
		fetch_url = [[NSString alloc] initWithFormat:@"%@%@.json%@", server,subreddit, after_post_param];
	else
		fetch_url = [[NSString alloc] initWithFormat:@"%@/.json%@",server, after_post_param];


//	fetch_url = [[NSString alloc] initWithFormat:@"file:///Volumes/media/Dev/AlienBlue/AlienBlue/home.json"];	
	
	NSLog(fetch_url);

	postFetchResultCallBackTarget = target;
	
	[self doGetURL:fetch_url callBackTarget:self callBackMethod:@"fetchPostResponse:" failedMethod:@"connectionFailedDialog:"];

}

- (void) subscribedRedditsResponse:(id) sender
{
	NSLog(@"subscribedRedditsResponse in()");
	NSData * data = (NSData *) sender;
	SBJSON *parser = [[SBJSON alloc] init];
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
//	NSLog(responseString);
	NSMutableDictionary *response = [parser objectWithString:responseString error:nil];
	if (subredditListCallBackTarget)
	{
		SEL action = NSSelectorFromString(@"apiSubredditsResponse:");
		[subredditListCallBackTarget performSelector:action withObject:response];
		//		[postFetchResultCallBackTarget performSelectorOnMainThread:action withObject:response waitUntilDone:NO];
	}	
	[data release];
	[responseString release];
	[parser release];
}



- (void) fetchSubscribedRedditsWithCallBackTarget:(id) target
{
	NSLog(@"fetchSubscribedRedditsWithCallBackTarget in()");
	
	NSString * subscribed_reddit_list_url = [[NSString alloc] initWithFormat:@"%@/reddits/mine/.json",server];
	NSLog(subscribed_reddit_list_url);
	
	subredditListCallBackTarget = target;
	
	[self doGetURL:subscribed_reddit_list_url callBackTarget:self callBackMethod:@"subscribedRedditsResponse:" failedMethod:@"connectionFailedDialog:"];
}







- (void) inboxFetchResponse:(id) sender
{
	NSLog(@"inboxFetchResponse in()");
	[self setLoadingMessages:NO];
	NSData * data = (NSData *) sender;
	SBJSON *parser = [[SBJSON alloc] init];
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];

	NSMutableDictionary *response = [parser objectWithString:responseString error:nil];	
	if (inboxCallBackTarget)
	{
		SEL action = NSSelectorFromString(@"apiInboxResponse:");
		[inboxCallBackTarget performSelector:action withObject:response];
	}
	
	// the mark=false flag does not work when using .json so we need to make an extra call
	// to /message/unread even though we will not need the response.  A call to this URL will
	// mark all unread messages as "read".
	if([[prefs valueForKey:@"auto_mark_as_read"] boolValue] && unreadMessageCount > 0)
	{
		NSLog(@"-- marking unread messages as read");

		[self setUnreadMessageCount:0];
		[(AlienBlueAppDelegate *) [[UIApplication sharedApplication] delegate] refreshUnreadMailBadge];

		NSString * fetch_url = [[NSString alloc] initWithFormat:@"%@/message/unread/", server];
//		NSString * fetch_url = [[NSString alloc] initWithFormat:@"%@/message/inbox/", server];
		[self doGetURL:fetch_url callBackTarget:nil callBackMethod:nil failedMethod:@"connectionFailedDialog:"];
	}
	
	[data release];
	[responseString release];
	[parser release];	
	
}



- (void) fetchMessageInboxAfterMessageID:(NSString *) messageID withCallBackTarget:(id) target
{
	NSLog(@"fetchMessageInboxWithCallBackTarget in()");

	[self setLoadingMessages:YES];
	int fetch_count = 25;
	NSString * fetch_url;
	NSString * after_post_param = @"";
	if ([messageID length] > 0)
		after_post_param = [[NSString alloc] initWithFormat:@"&limit=%d&after=%@", fetch_count, messageID];

	fetch_url = [[NSString alloc] initWithFormat:@"%@/message/inbox/.json?mark=false%@", server, after_post_param];		
	NSLog(fetch_url);	

	inboxCallBackTarget = target;
	
	[self doGetURL:fetch_url callBackTarget:self callBackMethod:@"inboxFetchResponse:" failedMethod:@"connectionFailedDialog:"];
}


- (void) unreadMessageCountFetchResponse:(id) sender
{
	NSLog(@"unreadMessageCountFetchResponse in()");
	NSData * data = (NSData *) sender;
	SBJSON *parser = [[SBJSON alloc] init];
	NSString * responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
//	NSLog(responseString);
	if ([responseString length] < 8)
	{
		NSLog(@"-- inbox access disallowed -- modhash/cookie may be expired");
		authenticated = NO;
		// this flag will also instruct the authenticate() method to hit the login API
	}
	else
	{
		NSLog(@"-- inbox access successful");
		authenticated = YES;		
	}
	
	NSMutableDictionary *response = [parser objectWithString:responseString error:nil];
	if (response)
	{
		NSArray * messages = [[response objectForKey:@"data"] objectForKey:@"children"];
		if (messages)
			unreadMessageCount = [messages count];
//		[messages release];
	}
	if (unreadMessageCountCallBackTarget)
	{
		SEL action = NSSelectorFromString(@"apiUnreadMessageCountResponse:");
		[unreadMessageCountCallBackTarget performSelector:action withObject:response];
	}	
	[responseString release];	
	[parser release];
	[data release];
}

- (void) fetchUnreadMessageCount:(id) target
{
	NSLog(@"fetchUnreadMessageCount in()");

	NSString * fetch_url;


	fetch_url = [[NSString alloc] initWithFormat:@"%@/message/unread/.json?mark=false",server];
	NSLog(fetch_url);	
	
	unreadMessageCountCallBackTarget = target;
	
	[self doGetURL:fetch_url callBackTarget:self callBackMethod:@"unreadMessageCountFetchResponse:" failedMethod:@"connectionFailedDialog:"];
	
}



+ (NSString *) useLowResImgurVersion:(NSString *) link
{
	if([link rangeOfString:@"imgur" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		NSMutableString * nlink = [NSMutableString stringWithString:link];
		[nlink replaceOccurrencesOfString:@".jpg" withString:@"l.jpg" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [nlink length])];
		[nlink replaceOccurrencesOfString:@".jpeg" withString:@"l.jpeg" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [nlink length])];
		[nlink replaceOccurrencesOfString:@".png" withString:@"l.png" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [nlink length])];
		return nlink;
	}
	else
		return link;
}


// this method allows drawing imgur links inline if the link isn't pointing directly
// to the image file.
+ (NSString *) fixImgurLink:(NSString *) link
{
	if(
	   [link rangeOfString:@".gif" options:NSCaseInsensitiveSearch].location == NSNotFound	&&
	   [link rangeOfString:@".png" options:NSCaseInsensitiveSearch].location == NSNotFound	&&
	   [link rangeOfString:@".jpg" options:NSCaseInsensitiveSearch].location == NSNotFound	&&
	   [link rangeOfString:@".jpeg" options:NSCaseInsensitiveSearch].location == NSNotFound &&
	   [link rangeOfString:@"imgur" options:NSCaseInsensitiveSearch].location != NSNotFound &&
	   [[NSUserDefaults standardUserDefaults] boolForKey:@"use_direct_imgur_link"]
	   )
	{
		// if there is no extension on an imgur link we add one here.  Imgur doesn't 
		// care about the type of extension, as long as one exists it will return the image.
		NSString * nlink = [link stringByAppendingString:@".jpg"];
		return nlink;
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"use_lowres_imgur"])
		link = [RedditAPI useLowResImgurVersion:link];
	
	return link;
}

+ (BOOL) isImageLink:(NSString *) link
{
	// we need to treat .gifs as non-images as they will not work when shown inline
	if([link rangeOfString:@".gif" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		return NO;
	}
	
	
	if(
	   [link rangeOfString:@".png" options:NSCaseInsensitiveSearch].location != NSNotFound	||
	   [link rangeOfString:@".jpg" options:NSCaseInsensitiveSearch].location != NSNotFound	||
	   [link rangeOfString:@".jpeg" options:NSCaseInsensitiveSearch].location != NSNotFound ||
	   ([link rangeOfString:@"imgur" options:NSCaseInsensitiveSearch].location != NSNotFound
		&& [[NSUserDefaults standardUserDefaults] boolForKey:@"use_direct_imgur_link"])
	   )
		return true;
	else
		return false;
}

+ (BOOL) isVideoLink:(NSString *) link
{
	if(
	   [link rangeOfString:@"youtube" options:NSCaseInsensitiveSearch].location != NSNotFound
	   )
		return true;
	else
		return false;
}

+ (BOOL) isSelfLink:(NSString *) link
{
	if(
	   [link rangeOfString:@"self." options:NSCaseInsensitiveSearch].location != NSNotFound ||
	   [link rangeOfString:@"reddit.com/comments/" options:NSCaseInsensitiveSearch].location != NSNotFound
	   )
		return true;
	else
		return false;
}


+ (NSString *) getLinkType:(NSString *) url
{
	NSString * linkType;
	if ([RedditAPI isImageLink:url])
		linkType = @"image";
	else if ([RedditAPI isVideoLink:url])
		linkType = @"video";
	else if ([RedditAPI isSelfLink:url])
		linkType = @"self";
	else
		linkType = @"article";
	return linkType;
}



@end