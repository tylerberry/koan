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

+ (instancetype) stateMachineWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState NS_DESIGNATED_INITIALIZER;

- (void) confirmTelnet;
- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;
- (void) reset;

@end
