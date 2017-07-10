//
// MUTelnetState.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetConstants.h"
#import "MUTelnetProtocolHandler.h"
#import "MUTelnetStateMachine.h"

@class MUByteSet;

@interface MUTelnetState : NSObject

+ (instancetype) state;

- (MUTelnetState *) parse: (uint8_t) byte
       forConnectionState: (MUMUDConnectionState *) connectionState
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;

@end
