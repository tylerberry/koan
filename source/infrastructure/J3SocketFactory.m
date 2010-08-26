//
// J3SocketFactory.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3SocketFactory.h"
#import "J3ProxySettings.h"
#import "J3ProxySocket.h"
#import "J3Socket.h"

static J3SocketFactory *defaultFactory = nil;

@interface J3SocketFactory (Private)

- (void) cleanUpDefaultFactory: (NSNotification *) notification;
- (void) loadProxySettingsFromDefaults;
- (void) writeProxySettingsToDefaults;

@end

#pragma mark -

@implementation J3SocketFactory

@synthesize useProxy, proxySettings;

+ (J3SocketFactory *) defaultFactory
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
  proxySettings = [[J3ProxySettings proxySettings] retain];
  
  return self;
}

- (void) dealloc
{
  [proxySettings release];
  [super dealloc];
}

- (J3Socket *) makeSocketWithHostname: (NSString *) hostname port: (int) port
{
  if (self.useProxy)
    return [J3ProxySocket socketWithHostname: hostname port: port proxySettings: self.proxySettings];
  else
    return [J3Socket socketWithHostname: hostname port: port];
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

@implementation J3SocketFactory (Private)

- (void) cleanUpDefaultFactory: (NSNotification *) notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: defaultFactory];
  [defaultFactory release];
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
  NSData *useProxyData = [NSKeyedArchiver archivedDataWithRootObject: [NSNumber numberWithBool: self.useProxy]];
  
  [[NSUserDefaults standardUserDefaults] setObject: proxySettingsData forKey: MUPProxySettings];  
  [[NSUserDefaults standardUserDefaults] setObject: useProxyData forKey: MUPUseProxy];
}

@end
