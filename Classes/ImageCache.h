//
//  ImageCache.h
//  AlienBlue
//
//  Created by Jason Morrissey on 17/05/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Resources.h"

@interface ImageCache : NSObject {

}

+ (UIImage *) imageForURL:(NSString *) urlString withCallBackTarget:(id) target;
+ (void) resetImageCache;
@end
