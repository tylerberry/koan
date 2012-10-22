//
// MUWorldViewController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorldViewController.h"

@implementation MUWorldViewController

- (id) init
{
  if (!(self = [super initWithNibName: @"MUWorldView" bundle: nil]))
    return nil;
  
  return self;
}

- (void) awakeFromNib
{
  self.view.autoresizingMask = NSViewWidthSizable;
}

@end
