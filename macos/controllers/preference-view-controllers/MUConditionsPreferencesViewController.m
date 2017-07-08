//
// MUConditionsPreferencesViewController.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUConditionsPreferencesViewController.h"

@implementation MUConditionsPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (instancetype) init
{
  if (!(self = [super initWithNibName: @"MUConditionsPreferencesView" bundle: nil]))
    return nil;

  _identifier = @"conditions";
  _toolbarItemImage = nil;
  _toolbarItemLabel = _(MULPreferencesConditions);

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  _conditionsArray = [NSKeyedUnarchiver unarchiveObjectWithData: [defaults objectForKey: MUPConditions]];

  return self;
}

@end
