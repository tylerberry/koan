//
// MUSocketFactory.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUMUDConnection.h"

@class MUProxySettings;

@interface MUSocketFactory : NSObject

+ (MUSocketFactory *) defaultFactory;

- (MUSocket *) makeSocketWithHostname: (NSString *) hostname port: (int) port;

@end
