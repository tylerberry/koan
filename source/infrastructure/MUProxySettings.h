//
// MUProxySettings.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUProxySettings : NSObject <NSCoding>

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (assign) BOOL requiresAuthentication;
@property (copy) NSString *username;
@property (copy) NSString *password;

@property (readonly) NSString *description;
@property (readonly) BOOL hasAuthentication;

+ (BOOL) isSystemSOCKSProxyEnabled;

+ (instancetype) systemSOCKSProxySettings;

- (instancetype) initWithHostname: (NSString *) newHostname port: (NSNumber *) newPort;

@end
