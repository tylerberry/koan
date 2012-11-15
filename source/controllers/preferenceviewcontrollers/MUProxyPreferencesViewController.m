//
// MUProxyPreferencesViewController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProxyPreferencesViewController.h"

@implementation MUProxyPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (id) init
{
  if (!(self = [super initWithNibName: @"MUProxyPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"proxy";
  _toolbarItemImage = nil;
  _toolbarItemLabel = _(MULPreferencesProxy);
  
  return self;
}
@end
