//
//  ImageCache.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 17/05/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "ImageCache.h"

static NSMutableDictionary * cache;

@implementation ImageCache

+ (void) resetImageCache
{
	if (cache)
		[cache release];
	cache = [[NSMutableDictionary alloc] init];	
}

+ (void)initialize {
	if (self == [ImageCache class]) {
		NSLog(@"ImageCache :: initialise in()");
		[self resetImageCache];
	}
}

+ (NSMutableDictionary *) cacheForURL:(NSString *) urlString
{
	for(NSString * connectionKey in cache){
		NSMutableDictionary * cachedItem = [cache objectForKey:connectionKey];
		NSString * cachedUrl = [cachedItem valueForKey:@"url"];
//		NSLog(@"-- in cache :: %@", cachedUrl);
		if (cachedUrl && [cachedUrl isEqualToString:urlString])
			return cachedItem;
	}
	return nil;
}

+ (UIImage *) imageForURL:(NSString *) urlString withCallBackTarget:(id) target
{
//	NSLog(@"ImageCache :: Image Requested :: %@", urlString);

	// handle invalid thumbnail links
	if (!urlString || [urlString length] == 0
		|| [urlString rangeOfString:@"noimage" options:NSCaseInsensitiveSearch].location != NSNotFound)
		return nil;

	NSMutableDictionary * cachedItem = [self cacheForURL:urlString];
	if (!cachedItem)
	{
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		[request setURL:[NSURL URLWithString:urlString]];
		NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
		NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
		NSMutableDictionary *dl = [[NSMutableDictionary alloc] init];
		[dl setValue:connectionKey forKey:@"connectionKey"];
		[dl setValue:[urlString copy] forKey:@"url"];
		[dl setValue:target forKey:@"afterCompleteTarget"];
		[dl setValue:@"loading" forKey:@"progress"];
		[cache setValue:dl forKey:connectionKey];
//		NSLog(@"ImageCache :: Image Requested :: %@", urlString);
	}
	else
	{
		// override the callback target... The request for caching may have been
		// made by the PostsTableController for pre-fetching.  The next time we call this
		// method, it may be from a different object, so we need to update it's callback target
		[cachedItem setValue:target forKey:@"afterCompleteTarget"];		

		// cached item
		if ([[cachedItem valueForKey:@"progress"] isEqualToString:@"finished"])
			return [cachedItem objectForKey:@"image"];
		
	}
	return [Resources loadingImage];
}

+ (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
//	NSLog(@"ImageCache :: connection : request");	
    return request;
}

+ (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//	NSLog(@"ImageCache :: connection : didReceiveResponse");
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * dl = [cache objectForKey:connectionKey];
	if (dl)
	{
		NSMutableData *data = [[NSMutableData alloc] init];
		[dl setObject:data forKey:@"data"];
	}
}

+ (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//	NSLog(@"ImageCache :: connection : didReceiveData");
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * dl = [cache objectForKey:connectionKey];
	if (dl)
	{
		NSMutableData * oldData = (NSMutableData *) [dl objectForKey:@"data"];
		[oldData appendData:data];
	}
}

+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//	NSLog(@"ImageCache :: connection : DidFailWithError"); 
}


+ (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
//	NSLog(@"ImageCache :: connection : connectionDidFinishLoading in()"); 
	NSString *connectionKey = [NSString stringWithFormat: @"%d", ((intptr_t) connection)];
	NSMutableDictionary * dl = [cache objectForKey:connectionKey];
	if (dl)
	{
		[dl setValue:@"finished" forKey:@"progress"];
		UIImage * image = [UIImage imageWithData:[dl objectForKey:@"data"]];
		[dl setValue:image forKey:@"image"];

		// perform necessary callbacks with the data.
		if ([dl objectForKey:@"afterCompleteTarget"])
		{
			SEL action = NSSelectorFromString(@"imageReadyCallback:");
			[[dl objectForKey:@"afterCompleteTarget"] performSelector:action withObject:image];
		}	
		[[dl objectForKey:@"data"] release];
	}
//	[cache removeObjectForKey:connectionKey];
//	[connectionKey release];
//	[dl release];
}


- (void)dealloc {
	if (cache)
		[cache release];
    [super dealloc];
}

@end
