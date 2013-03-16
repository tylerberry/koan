//
// MUSocketFactory.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnection.h"
#import "MUSocket.h"

@class MUProxySettings;

@interface MUSocketFactory : NSObject

+ (MUSocketFactory *) defaultFactory;

- (MUSocket *) makeSocketWithHostname: (NSString *) hostname port: (int) port;

@end
