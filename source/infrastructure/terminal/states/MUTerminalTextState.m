//
// MUTerminalTextState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalTextState.h"

#import "MUTerminalEscapeState.h"

@implementation MUTerminalTextState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  if (byte == 0x1b)
  {
    [protocolHandler bufferTextByte: byte];
    return [MUTerminalEscapeState state];
  }
  else
  {
    [protocolHandler bufferTextByte: byte];
    return self;
  }
}

@end
