//
// MUTerminalState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalState.h"

@implementation MUTerminalState

+ (id) state
{
  return [MUTerminalState new];
}

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  [protocolHandler bufferTextByte: byte];
  return self;
}

@end
