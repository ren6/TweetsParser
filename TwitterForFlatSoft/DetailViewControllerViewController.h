//
//  DetailViewControllerViewController.h
//  TwitterForFlatSoft
//
//  Created by Renat on 24.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewControllerViewController : UIViewController
@property (nonatomic,retain) IBOutlet UIImageView *imageView;
@property (nonatomic,retain) IBOutlet UILabel *label;
@property (nonatomic,retain) IBOutlet UILabel *labelDate;
@property (nonatomic,retain) IBOutlet UITextView *textView;

@end
