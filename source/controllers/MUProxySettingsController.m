//
// MUProxySettingsController.m
//
// Copyright (c) 2010 3James Software.
//

#import "MUProxySettingsController.h"
#import "J3SocketFactory.h"
#import "J3PortFormatter.h"
#import "J3ProxySettings.h"

@implementation MUProxySettingsController

- (id) init
{
  self = [super initWithWindowNibName: @"MUProxySettings"];
  
  return self;
}

- (void) awakeFromNib
{
  J3PortFormatter *portFormatter = [[[J3PortFormatter alloc] init] autorelease];
  
  [portField setFormatter: portFormatter];
}

- (J3ProxySettings *) proxySettings
{
  return [[J3SocketFactory defaultFactory] proxySettings];
}

@end
