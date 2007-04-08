//
// MUProxySettingsController.m
//
// Copyright (c) 2007 3James Software.
//

#import "MUProxySettingsController.h"
#import "J3SocketFactory.h"
#import "J3PortFormatter.h"
#import "J3ProxySettings.h"

@implementation MUProxySettingsController

- (void) awakeFromNib
{
  J3PortFormatter *portFormatter = [[[J3PortFormatter alloc] init] autorelease];
  
  [portField setFormatter: portFormatter];
}

- (id) init
{
  return [super initWithWindowNibName: @"MUProxySettings"];
}

- (J3ProxySettings *) proxySettings
{
  return [[J3SocketFactory defaultFactory] proxySettings];
}

@end
