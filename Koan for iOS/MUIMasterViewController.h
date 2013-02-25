//
//  MUIMasterViewController.h
//  Koan for iOS
//
//  Created by Tyler Berry on 2/20/13.
//  Copyright (c) 2013 3James Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MUIDetailViewController;

@interface MUIMasterViewController : UITableViewController

@property (strong, nonatomic) MUIDetailViewController *detailViewController;

@end
