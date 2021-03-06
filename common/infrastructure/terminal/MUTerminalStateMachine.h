//
// MUTerminalStateMachine.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"

#import "MUMUDConnectionState.h"

@class MUTerminalState;

@interface MUTerminalStateMachine : NSObject

@property (strong) MUMUDConnectionState *connectionState;
@property (strong) MUTerminalState *state;

+ (instancetype) stateMachineWithConnectionState: (MUMUDConnectionState *) connectionState;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState NS_DESIGNATED_INITIALIZER;

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler;
- (void) reset;

@end
