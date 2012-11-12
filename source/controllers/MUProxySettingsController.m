//
// MUProxySettingsController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProxySettingsController.h"
#import "MUSocketFactory.h"
#import "MUPortFormatter.h"
#import "MUProxySettings.h"

@implementation MUProxySettingsController

- (id) init
{
  self = [super initWithWindowNibName: @"MUProxySettings" owner: self];
  
  return self;
}

- (void) awakeFromNib
{
  MUPortFormatter *portFormatter = [[MUPortFormatter alloc] init];
  
  [portField setFormatter: portFormatter];
}

- (MUProxySettings *) proxySettings
{
  return [[MUSocketFactory defaultFactory] proxySettings];
}

@end
