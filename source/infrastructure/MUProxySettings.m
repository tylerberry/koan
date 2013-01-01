//
// MUProxySettings.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProxySettings.h"

#import <SystemConfiguration/SystemConfiguration.h>

static const int32_t currentProxyVersion = 3;

@implementation MUProxySettings

@dynamic description, hasAuthentication;

+ (BOOL) isSystemSOCKSProxyEnabled
{
  CFDictionaryRef proxySettings = SCDynamicStoreCopyProxies (NULL);
  
  if (!proxySettings)
    return NO;
  
  NSNumber *systemSOCKSProxyEnabled = (NSNumber *) CFDictionaryGetValue (proxySettings, kSCPropNetProxiesSOCKSEnable);
  
  if ([systemSOCKSProxyEnabled integerValue] == 1)
  {
    CFRelease (proxySettings);
    return YES;
  }
  else
  {
    CFRelease (proxySettings);
    return NO;
  }
}

+ (MUProxySettings *) systemSOCKSProxySettings
{
  CFDictionaryRef proxySettings = SCDynamicStoreCopyProxies (NULL);
  
  if (!proxySettings)
    return nil;
  
  NSNumber *systemSOCKSProxyEnabled = (NSNumber *) CFDictionaryGetValue (proxySettings, kSCPropNetProxiesSOCKSEnable);
  
  if ([systemSOCKSProxyEnabled integerValue] == 1)
  {
    NSString *systemSOCKSProxyHostname = (NSString *) CFDictionaryGetValue (proxySettings, kSCPropNetProxiesSOCKSProxy);
    NSNumber *systemSOCKSProxyPort = (NSNumber *) CFDictionaryGetValue (proxySettings, kSCPropNetProxiesSOCKSPort);
  
    MUProxySettings *systemSOCKSProxySettings = [[self alloc] initWithHostname: systemSOCKSProxyHostname
                                                                          port: systemSOCKSProxyPort];
    
    CFRelease (proxySettings);
    return systemSOCKSProxySettings;
  }
  else
  {
    CFRelease (proxySettings);
    return nil;
  }
}

+ (MUProxySettings *) proxySettings
{
  return [[self alloc] init];
}

- (id) initWithHostname: (NSString *) newHostname port: (NSNumber *) newPort
{
  if (!(self = [super init]))
    return nil;
  
  _hostname = [newHostname copy];
  _port = [newPort copy];
  _requiresAuthentication = NO;
  _username = @"";
  _password = @"";
  
  return self;
}

- (id) init
{
  return [self initWithHostname: @"" port: @1080];
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
  int32_t version = [coder decodeInt32ForKey: @"version"];
  
  if (!(self = [self initWithHostname: [coder decodeObjectForKey: @"hostname"]
                                 port: [coder decodeObjectForKey: @"port"]]))
    return nil;
  
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
