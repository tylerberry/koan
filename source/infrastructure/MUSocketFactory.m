//
// MUSocketFactory.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUSocketFactory.h"
#import "MUProxySettings.h"
#import "MUProxySocket.h"
#import "MUSocket.h"

@interface MUSocketFactory ()

- (void) _loadProxySettingsFromDefaults;
- (void) _writeProxySettingsToDefaults;

@end

#pragma mark -

@implementation MUSocketFactory

@synthesize useProxy, proxySettings;

+ (MUSocketFactory *) defaultFactory
{
  static MUSocketFactory *defaultFactory = nil;  
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    defaultFactory = [[self alloc] init];
    [defaultFactory _loadProxySettingsFromDefaults];
  });

  return defaultFactory;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  useProxy = NO;
  proxySettings = [MUProxySettings proxySettings];
  
  return self;
}

- (MUSocket *) makeSocketWithHostname: (NSString *) hostname port: (int) port
{
  if (self.useProxy)
    return [MUProxySocket socketWithHostname: hostname port: port proxySettings: self.proxySettings];
  else
    return [MUSocket socketWithHostname: hostname port: port];
}

- (void) saveProxySettings
{
  [self _writeProxySettingsToDefaults];
}

- (void) toggleUseProxy
{
  self.useProxy = !self.useProxy;
}

#pragma mark - Private methods

- (void) _loadProxySettingsFromDefaults
{
  NSData *proxySettingsData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPProxySettings];
  NSData *useProxyData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPUseProxy];
  
  if (proxySettingsData)
    self.proxySettings = [NSKeyedUnarchiver unarchiveObjectWithData: proxySettingsData];
  if (useProxyData)
    self.useProxy = [[NSKeyedUnarchiver unarchiveObjectWithData: useProxyData] boolValue];
}

- (void) _writeProxySettingsToDefaults
{
  NSData *proxySettingsData = [NSKeyedArchiver archivedDataWithRootObject: self.proxySettings];
  NSData *useProxyData = [NSKeyedArchiver archivedDataWithRootObject: @(self.useProxy)];
  
  [[NSUserDefaults standardUserDefaults] setObject: proxySettingsData forKey: MUPProxySettings];  
  [[NSUserDefaults standardUserDefaults] setObject: useProxyData forKey: MUPUseProxy];
}

@end
