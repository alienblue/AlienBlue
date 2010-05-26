//
//  Resources.h
//  AlienBlue
//
//  Created by Jason Morrissey on 5/05/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RedditAPI.h"

@interface Resources : NSObject {

}

+ (UIImage *) barImage;
+ (UIImage *) loadingImage;

+ (UIColor *) cOrange;
+ (UIColor *) cGreen;
+ (UIColor *) cNormal;
+ (UIColor *) cBlue;
+ (UIColor *) cTitleColor;

+ (UIFont *) mainFont;
+ (UIFont *) secondaryFont;
+ (UIFont *) tertiaryFont;

+ (UIImage *) videoIcon;
+ (UIImage *) articleIcon;
+ (UIImage *) imageIcon;

+ (UIImage *) rightArrowDimImage;

+ (void) processPost:(NSMutableDictionary *) post;

@end
