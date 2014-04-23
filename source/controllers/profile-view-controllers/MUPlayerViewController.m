//
// MUPlayerViewController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUPlayerViewController.h"

@implementation MUPlayerViewController

- (id) init
{
  if (!(self = [super initWithNibName: @"MUEditPlayerView" bundle: nil]))
    return nil;
  
  return self;
}

- (void) awakeFromNib
{
  self.view.autoresizingMask = NSViewWidthSizable;
}

@end
