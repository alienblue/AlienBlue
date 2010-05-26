//
//  PostCell.h
//  Alien Blue
//
//  Created by Jason Morrissey on 28/03/10.
//  Copyright 2010 The Design Shed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageCache.h"

@interface PostCell : UITableViewCell {
	NSMutableDictionary * post;
	UIViewController * postController;
	CGRect buttonFrame;
	BOOL isEditing;
}

@property (nonatomic, retain) NSMutableDictionary *post;
@property (nonatomic, retain) UIViewController * postController;

- (IBAction) imageReadyCallback: (id)sender;

@end
