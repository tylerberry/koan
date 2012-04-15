//
//  MUIMasterViewController.h
//  Koan for iOS
//
//  Created by Tyler Berry on 4/15/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MUIDetailViewController;

@interface MUIMasterViewController : UITableViewController
{
  NSMutableArray *_objects;
}

@property (strong, nonatomic) MUIDetailViewController *detailViewController;

@end
