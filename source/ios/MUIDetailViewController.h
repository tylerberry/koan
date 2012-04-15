//
//  MUIDetailViewController.h
//  Koan for iOS
//
//  Created by Tyler Berry on 4/15/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MUIDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
