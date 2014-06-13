//
// MUProxySocket.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUSocket.h"

@class MUProxySettings;
@class MUWriteBuffer;

@interface MUProxySocket : MUSocket

+ (instancetype) socketWithHostname: (NSString *) hostname
                               port: (uint16_t) port
                      proxySettings: (MUProxySettings *) settings;

- (instancetype) initWithHostname: (NSString *) hostname
                             port: (uint16_t) port
                    proxySettings: (MUProxySettings *) settings;

@end
