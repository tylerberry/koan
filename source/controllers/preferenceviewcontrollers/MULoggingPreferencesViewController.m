//
// MULoggingPreferencesViewController.m
//
// Copyright (c) 2013 3James Software. All rights reserved.
//

#import "MULoggingPreferencesViewController.h"

@implementation MULoggingPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (id) init
{
  if (!(self = [super initWithNibName: @"MULoggingPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"logging";
  _toolbarItemImage = nil;
  _toolbarItemLabel = _(MULPreferencesLogging);
  
  return self;
}


@end
