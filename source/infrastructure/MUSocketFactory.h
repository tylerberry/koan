//
// MUSocketFactory.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUMUDConnection.h"

@class MUProxySettings;

@interface MUSocketFactory : NSObject

@property (assign, nonatomic) BOOL useProxy;
@property (strong) MUProxySettings *proxySettings;

+ (MUSocketFactory *) defaultFactory;

- (MUSocket *) makeSocketWithHostname: (NSString *) hostname port: (int) port;

@end
