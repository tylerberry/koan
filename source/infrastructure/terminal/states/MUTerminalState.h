//
// MUTerminalState.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"
#import "MUTerminalStateMachine.h"

@interface MUTerminalState : NSObject

+ (instancetype) state;

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler;

@end
