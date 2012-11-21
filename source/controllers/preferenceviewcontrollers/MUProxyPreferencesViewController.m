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
@dynamic shouldEnableCustomProxyControls;

- (id) init
{
  if (!(self = [super initWithNibName: @"MUProxyPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"proxy";
  _toolbarItemImage = nil;
  _toolbarItemLabel = _(MULPreferencesProxy);
  
  return self;
}

- (void) awakeFromNib
{
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  NSNumber *useProxyNumber = [userDefaultsController.values valueForKey: MUPUseProxy];
  
  [proxyRadioButtonMatrix selectCellWithTag: useProxyNumber.integerValue];
}

#pragma mark - Property methods

- (BOOL) shouldEnableCustomProxyControls
{
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  NSNumber *useProxyNumber = [userDefaultsController.values valueForKey: MUPUseProxy];
  
  return (useProxyNumber.integerValue == 2);
}

#pragma mark - Actions

- (IBAction) proxyRadioButtonClicked: (id) sender
{
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [self willChangeValueForKey: @"shouldEnableCustomProxyControls"];
  [userDefaultsController.values setValue: @([proxyRadioButtonMatrix selectedTag]) forKey: MUPUseProxy];
  [self didChangeValueForKey: @"shouldEnableCustomProxyControls"];
}

@end
