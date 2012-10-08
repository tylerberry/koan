//
// MUSocketFactory.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUSocketFactory.h"
#import "MUProxySettings.h"
#import "MUProxySocket.h"
#import "MUSocket.h"

static MUSocketFactory *defaultFactory = nil;

@interface MUSocketFactory (Private)

- (void) cleanUpDefaultFactory: (NSNotification *) notification;
- (void) loadProxySettingsFromDefaults;
- (void) writeProxySettingsToDefaults;

@end

#pragma mark -

@implementation MUSocketFactory

@synthesize useProxy, proxySettings;

+ (MUSocketFactory *) defaultFactory
{
  if (!defaultFactory)
  {
    defaultFactory = [[self alloc] init];
    [defaultFactory loadProxySettingsFromDefaults];
    
    [[NSNotificationCenter defaultCenter] addObserver: defaultFactory
                                             selector: @selector (cleanUpDefaultFactory:)
                                                 name: NSApplicationWillTerminateNotification
                                               object: NSApp];
  }
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
  [self writeProxySettingsToDefaults];
}

- (void) toggleUseProxy
{
  self.useProxy = !self.useProxy;
}

@end

#pragma mark -

@implementation MUSocketFactory (Private)

- (void) cleanUpDefaultFactory: (NSNotification *) notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: defaultFactory];
  defaultFactory = nil;
}

- (void) loadProxySettingsFromDefaults
{
  NSData *proxySettingsData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPProxySettings];
  NSData *useProxyData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPUseProxy];
  
  if (proxySettingsData)
    self.proxySettings = [NSKeyedUnarchiver unarchiveObjectWithData: proxySettingsData];
  if (useProxyData)
    self.useProxy = [[NSKeyedUnarchiver unarchiveObjectWithData: useProxyData] boolValue];
}

- (void) writeProxySettingsToDefaults
{
  NSData *proxySettingsData = [NSKeyedArchiver archivedDataWithRootObject: self.proxySettings];
  NSData *useProxyData = [NSKeyedArchiver archivedDataWithRootObject: @(self.useProxy)];
  
  [[NSUserDefaults standardUserDefaults] setObject: proxySettingsData forKey: MUPProxySettings];  
  [[NSUserDefaults standardUserDefaults] setObject: useProxyData forKey: MUPUseProxy];
}

@end
