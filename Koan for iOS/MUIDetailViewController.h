//
// MUIDetailViewController.h
//
// Copyright (c) 2013 3James Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MUIDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
