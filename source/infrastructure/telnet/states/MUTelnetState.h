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

+ (id) state;

+ (MUByteSet *) telnetCommandBytes;

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;

@end
