//
// MUTelnetStateMachine.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetProtocolHandler.h"
#import "MUTelnetState.h"

@class MUTelnetState;

@interface MUTelnetStateMachine : NSObject

@property (strong) MUTelnetState *state;
@property (readonly) BOOL telnetConfirmed;

+ (id) stateMachine;

- (void) confirmTelnet;
- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;

@end
