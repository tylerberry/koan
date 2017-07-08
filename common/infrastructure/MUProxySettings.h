//
// MUProxySettings.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUProxySettings : NSObject <NSSecureCoding>

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (assign) BOOL requiresAuthentication;
@property (copy) NSString *username;
@property (copy) NSString *password;

@property (readonly) NSString *description;
@property (readonly) BOOL hasAuthentication;

+ (BOOL) isSystemSOCKSProxyEnabled;

+ (instancetype) systemSOCKSProxySettings;
w
- (instancetype) initWithHostname: (NSString *) newHostname port: (NSNumber *) newPort NS_DESIGNATED_INITIALIZER;

@end
