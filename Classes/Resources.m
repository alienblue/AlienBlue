//
//  Resources.m
//  Alien Blue :: http://alienblue.org
//
//  Created by Jason Morrissey on 5/05/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import "Resources.h"
static UIImage *barImage;
static UIImage *barImageDark;

static UIColor * cTitleDark;
static UIColor * cTitleNormal;

static UIColor * cOrange;
static UIColor * cGreen;
static UIColor * cNormal;
static UIColor * cNormalDark;
static UIColor * cBlue;

static UIFont *mainFont;
static UIFont *secondaryFont;
static UIFont *tertiaryFont;

static UIFont *mainFontLarge;
static UIFont *secondaryFontLarge;
static UIFont *tertiaryFontLarge;

static UIFont *mainFontSmall;
static UIFont *secondaryFontSmall;
static UIFont *tertiaryFontSmall;


static UIImage * videoIcon;
static UIImage * articleIcon;
static UIImage * imageIcon;

static UIImage * rightArrowDim;

static UIImage *loadingImageIcon;

static NSUserDefaults * prefs;

#define MAIN_FONT_SIZE 16
#define SECONDARY_FONT_SIZE 14
#define TERTIARY_FONT_SIZE 12


@implementation Resources

+ (void)initialize {
	if (self == [Resources class]) {
		NSLog(@"Resources :: initialise in()");
		prefs = [NSUserDefaults standardUserDefaults];
		barImage = [[UIImage imageNamed:@"button-background.png"] retain];
		barImageDark = [[UIImage imageNamed:@"button-background-dark.png"] retain];
		loadingImageIcon = [[UIImage imageNamed:@"loading-icon.png"] retain];

		mainFont = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		secondaryFont = [UIFont systemFontOfSize:SECONDARY_FONT_SIZE];
		tertiaryFont = [UIFont systemFontOfSize:TERTIARY_FONT_SIZE];

		mainFontSmall = [UIFont systemFontOfSize:MAIN_FONT_SIZE - 2];
		secondaryFontSmall = [UIFont systemFontOfSize:SECONDARY_FONT_SIZE - 1];
		tertiaryFontSmall = [UIFont systemFontOfSize:TERTIARY_FONT_SIZE];

		mainFontLarge = [UIFont systemFontOfSize:MAIN_FONT_SIZE + 2];
		secondaryFontLarge = [UIFont systemFontOfSize:SECONDARY_FONT_SIZE + 1];
		tertiaryFontLarge = [UIFont systemFontOfSize:TERTIARY_FONT_SIZE];
		
		cOrange = [[UIColor colorWithRed:1.0 green:1.0 blue:0.1 alpha:1] retain];
		cGreen = [[UIColor colorWithRed:0.8 green:1.0 blue:0.4 alpha:1] retain];
		cNormal = [[UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1] retain];
		cNormalDark = [[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1] retain];
		cTitleNormal = [[UIColor colorWithWhite:1 alpha:1] retain];
		cTitleDark = [[UIColor colorWithWhite:0.85 alpha:1] retain];
		cBlue = [[UIColor colorWithRed:0.6 green:0.6 blue:1 alpha:1] retain];
		
		videoIcon = [[UIImage imageNamed:@"video-icon.png"] retain];	
		articleIcon = [[UIImage imageNamed:@"article-icon.png"] retain];
		imageIcon = [[UIImage imageNamed:@"image-icon.png"] retain];
		
		rightArrowDim = [[UIImage imageNamed:@"right-arrow-dim.png"] retain];		
		
	}
}

+ (UIImage *) rightArrowDimImage 
{
	return rightArrowDim; 
}


+ (UIImage *) loadingImage 
{
	return loadingImageIcon;
}


+ (UIImage *) videoIcon 
{
	return videoIcon; 
}

+ (UIImage *) articleIcon 
{
	return articleIcon; 
}

+ (UIImage *) imageIcon 
{
	return imageIcon; 
}





+ (UIImage *) barImage 
{
	if ([prefs boolForKey:@"night_mode"])
		return barImageDark; 
	else
		return barImage; 
}

+ (UIColor *) cTitleColor
{
	if ([prefs boolForKey:@"night_mode"])
		return cTitleDark; 
	else
		return cTitleNormal;	
	
}

+ (UIColor *) cNormal 
{ 
	if ([prefs boolForKey:@"night_mode"])
		return cNormalDark; 
	else
		return cNormal;	
}

+ (UIColor *) cOrange { return cOrange; }
+ (UIColor *) cGreen { return cGreen; }
+ (UIColor *) cBlue { return cBlue; }

+ (UIFont *) mainFont { 
	int tsize = [prefs integerForKey:@"textsize"];
	if (tsize == 0)
		return mainFontSmall;
	else if (tsize == 1)
		return mainFont;
	else
		return mainFontLarge; 
}

+ (UIFont *) secondaryFont { 
	int tsize = [prefs integerForKey:@"textsize"];
	if (tsize == 0)
		return secondaryFontSmall;
	else if (tsize == 1)
		return secondaryFont;
	else
		return secondaryFontLarge; 
}

+ (UIFont *) tertiaryFont {
	int tsize = [prefs integerForKey:@"textsize"];
	if (tsize == 0)
		return tertiaryFontSmall;
	else if (tsize == 1)
		return tertiaryFont;
	else
		return tertiaryFontLarge; 
}

+ (void) processPost:(NSMutableDictionary *) post
{
	int voteDirection = 0;
	if(![[post objectForKey:@"likes"] isKindOfClass:[NSNull class]] && [[post valueForKey:@"likes"] boolValue])
		voteDirection = 1;
	else if(![[post objectForKey:@"likes"] isKindOfClass:[NSNull class]] && ![[post valueForKey:@"likes"] boolValue])
		voteDirection = -1;
	[post setValue:[NSNumber numberWithInt:voteDirection] forKey:@"voteDirection"];
	[post setValue:[[post valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"] forKey:@"title"];
	[post setValue:[[post valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"] forKey:@"title"];
	[post setValue:[[post valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"] forKey:@"title"];			
	// calculate score (for some reason, the live reddit.com server doesn't compute the score
	// for comments, so we do this manually:
	int ups = [[post valueForKey:@"ups"] intValue];
	int downs = [[post valueForKey:@"downs"] intValue];
	[post setValue:[NSNumber numberWithInt:(ups - downs)] forKey:@"score"];
	
	[post setValue:[RedditAPI getLinkType:[post valueForKey:@"url"]] forKey:@"type"];
	[post setValue:[RedditAPI fixImgurLink:[post valueForKey:@"url"]] forKey:@"url"];

}





@end
