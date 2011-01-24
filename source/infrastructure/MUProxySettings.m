//
// MUProxySettings.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUProxySettings.h"
#import "MUCodingService.h"

@implementation MUProxySettings

@synthesize hostname, port, username, password;

+ (id) proxySettings
{
  return [[[self alloc] init] autorelease];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  hostname = [[NSString alloc] initWithString: @""];
  port = [[NSNumber alloc] initWithInt: 1080];
  
  return self;
}

- (void) dealloc
{
  [hostname release];
  [port release];
  [username release];
  [password release];
  [super dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@: %@", hostname, port];
}

- (BOOL) hasAuthentication
{
  return username && ([username length] > 0);
}

#pragma mark -
#pragma mark NSCoding protocol

- (id) initWithCoder: (NSCoder *) coder
{
  [MUCodingService decodeProxySettings: self withCoder: coder];
  return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [MUCodingService encodeProxySettings: self withCoder: coder];
}

@end
