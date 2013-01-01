//
// MUProxySocket.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUSocket.h"

@class MUProxySettings;
@class MUWriteBuffer;

@interface MUProxySocket : MUSocket
{
  MUProxySettings *proxySettings;
  NSString *realHostname;
  int realPort;
  MUWriteBuffer *outputBuffer;
}

+ (id) socketWithHostname: (NSString *) hostname
                     port: (int) port
            proxySettings: (MUProxySettings *) settings;

- (id) initWithHostname: (NSString *) hostname
                   port: (int) port
          proxySettings: (MUProxySettings *) settings;

@end
