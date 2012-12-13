//
// MUSocketFactory.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUSocketFactory.h"
#import "MUProxySettings.h"
#import "MUProxySocket.h"
#import "MUSocket.h"

@implementation MUSocketFactory

+ (MUSocketFactory *) defaultFactory
{
  static MUSocketFactory *defaultFactory = nil;  
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ defaultFactory = [[self alloc] init]; });

  return defaultFactory;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  return self;
}

- (MUSocket *) makeSocketWithHostname: (NSString *) hostname port: (int) port
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  if ([userDefaults integerForKey: MUPUseProxy] == 2)
  {
    NSData *proxySettingsData = [userDefaults dataForKey: MUPProxySettings];
    return [MUProxySocket socketWithHostname: hostname
                                        port: port
                               proxySettings: [NSKeyedUnarchiver unarchiveObjectWithData: proxySettingsData]];
  }
  else
    return [MUSocket socketWithHostname: hostname port: port];
}

@end
