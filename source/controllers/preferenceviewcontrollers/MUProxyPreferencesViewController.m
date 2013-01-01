//
// MUProxyPreferencesViewController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProxyPreferencesViewController.h"

@interface MUProxyPreferencesViewController ()

- (NSImage *) _createProxyIcon;

@end

#pragma mark -

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
  _toolbarItemImage = [self _createProxyIcon];
  _toolbarItemLabel = _(MULPreferencesProxy);
  
  return self;
}

- (void) awakeFromNib
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSNumber *useProxyNumber = [userDefaults objectForKey: MUPUseProxy];
  
  [proxyRadioButtonMatrix selectCellWithTag: useProxyNumber.integerValue];
}

#pragma mark - Property methods

- (BOOL) shouldEnableCustomProxyControls
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSNumber *useProxyNumber = [userDefaults objectForKey: MUPUseProxy];
  
  return (useProxyNumber.integerValue == 2);
}

#pragma mark - Actions

- (IBAction) proxyRadioButtonClicked: (id) sender
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [self willChangeValueForKey: @"shouldEnableCustomProxyControls"];
  [userDefaults setInteger: proxyRadioButtonMatrix.selectedTag forKey: MUPUseProxy];
  [self didChangeValueForKey: @"shouldEnableCustomProxyControls"];
}

#pragma mark - Private methods

- (NSImage *) _createProxyIcon
{
  NSImage *proxyImage = [[NSImage alloc] initWithSize: NSMakeSize (32.0, 32.0)];
  NSImage *networkImage = [NSImage imageNamed: @"NSNetwork"];
  NSImage *gearImage = [NSImage imageNamed: @"NSAdvanced"];
  
  proxyImage.size = NSMakeSize (32.0, 32.0);
  gearImage.size = NSMakeSize (22.0, 22.0);
  
  [proxyImage lockFocus];
  [networkImage drawAtPoint: NSMakePoint (0.0, 0)
                fromRect: NSZeroRect
               operation: NSCompositeDestinationOver
                   fraction: 1.0];
  [gearImage drawAtPoint: NSMakePoint (10.0, 0)
                fromRect: NSZeroRect
               operation: NSCompositeSourceOver
                fraction: 1.0];
  [proxyImage unlockFocus];
  
  return proxyImage;
}

@end
