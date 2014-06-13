//
// MUTerminalStateMachine.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"

@class MUTerminalState;

@interface MUTerminalStateMachine : NSObject

@property (strong) MUTerminalState *state;

+ (instancetype) stateMachine;

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler;
- (void) reset;

@end
