//
// MUProxySettings.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUProxySettings : NSObject <NSCoding>

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (assign) BOOL requiresAuthentication;
@property (copy) NSString *username;
@property (copy) NSString *password;

@property (readonly) NSString *description;
@property (readonly) BOOL hasAuthentication;

+ (id) proxySettings;

@end
