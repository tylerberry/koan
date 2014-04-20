//
// MUIMasterViewController.h
//
// Copyright (c) 2013 3James Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MUIDetailViewController;

@interface MUIMasterViewController : UITableViewController

@property (strong, nonatomic) MUIDetailViewController *detailViewController;

@end
