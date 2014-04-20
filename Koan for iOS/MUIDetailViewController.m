//
//  MUIDetailViewController.m
//  Koan for iOS
//
//  Created by Tyler Berry on 2/20/13.
//  Copyright (c) 2013 3James Software. All rights reserved.
//

#import "MUIDetailViewController.h"

@interface MUIDetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void) configureView;

@end

@implementation MUIDetailViewController

#pragma mark - Managing the detail item

- (void) setDetailItem: (id) newDetailItem
{
  if (_detailItem != newDetailItem)
  {
    _detailItem = newDetailItem;
    
    // Update the view.
    [self configureView];
  }
  
  if (self.masterPopoverController != nil)
  {
    [self.masterPopoverController dismissPopoverAnimated: YES];
  }
}

- (void) configureView
{
  // Update the user interface for the detail item.
  
  if (self.detailItem)
  {
    self.detailDescriptionLabel.text = self.detailItem.description;
  }
}

- (void) viewDidLoad
{
  [super viewDidLoad];

  // Do any additional setup after loading the view, typically from a nib.
  [self configureView];
}

- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];

  // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void) splitViewController: (UISplitViewController *) splitController
      willHideViewController: (UIViewController *) viewController
           withBarButtonItem: (UIBarButtonItem *) barButtonItem
        forPopoverController: (UIPopoverController *) popoverController
{
  barButtonItem.title = NSLocalizedString (@"Master", nil);
  [self.navigationItem setLeftBarButtonItem: barButtonItem animated: YES];
  self.masterPopoverController = popoverController;
}

- (void) splitViewController: (UISplitViewController *) splitController
      willShowViewController: (UIViewController *) viewController
   invalidatingBarButtonItem: (UIBarButtonItem *) barButtonItem
{
  // Called when the view is shown again in the split view, invalidating the button and popover controller.
  [self.navigationItem setLeftBarButtonItem: nil animated: YES];
  self.masterPopoverController = nil;
}

@end
