//
// MUProxySettings.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProxySettings.h"

static const int32_t currentProxyVersion = 3;

@implementation MUProxySettings

@dynamic description, hasAuthentication;

+ (id) proxySettings
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _hostname = @"";
  _port = @1080;
  _requiresAuthentication = NO;
  _username = @"";
  _password = @"";
  
  return self;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@: %@", self.hostname, self.port];
}

- (BOOL) hasAuthentication
{
  return self.username && self.username.length > 0;
}

#pragma mark - NSCoding protocol

- (id) initWithCoder: (NSCoder *) coder
{
  if (!(self = [super init]))
    return nil;
  
  int32_t version = [coder decodeInt32ForKey: @"version"];
  
  _hostname = [coder decodeObjectForKey: @"hostname"];
  _port = [coder decodeObjectForKey: @"port"];
  
  if (version >= 2)
  {
    _username = [coder decodeObjectForKey: @"username"];
    _password = [coder decodeObjectForKey: @"password"];
  }
  else
  {
    _username = @"";
    _password = @"";
  }
  
  if (version >= 3)
    _requiresAuthentication = [coder decodeBoolForKey: @"requiresAuthentication"];
  else
  {
    if (_username && _username.length > 0)
      _requiresAuthentication = YES;
    else
      _requiresAuthentication = NO;
  }
  
  return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [coder encodeInt32: currentProxyVersion forKey: @"version"];
  
  [coder encodeObject: self.hostname forKey: @"hostname"];
  [coder encodeObject: self.port forKey: @"port"];
  [coder encodeObject: self.username forKey: @"username"];
  [coder encodeObject: self.password forKey: @"password"];
}

@end
