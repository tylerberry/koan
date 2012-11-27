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
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  NSNumber *useProxyNumber = [userDefaultsController.values valueForKey: MUPUseProxy];
  
  if (useProxyNumber.integerValue == 2)
  {
    NSData *proxySettingsData = [userDefaultsController.values valueForKey: MUPProxySettings];
    return [MUProxySocket socketWithHostname: hostname
                                        port: port
                               proxySettings: [NSKeyedUnarchiver unarchiveObjectWithData: proxySettingsData]];
  }
  else
    return [MUSocket socketWithHostname: hostname port: port];
}

@end
