//
// MUProxySettings.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUProxySettings : NSObject <NSCoding>
{
  NSString *hostname;
  NSNumber *port;
  NSString *username;
  NSString *password;
}

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (copy) NSString *username;
@property (copy) NSString *password;

+ (id) proxySettings;

- (NSString *) description;
- (BOOL) hasAuthentication;

@end
