//
// MUTerminalEscapeState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalEscapeState.h"

#import "MUTerminalCSIState.h"
#import "MUTerminalTextState.h"

@implementation MUTerminalEscapeState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  if (byte == '[')
  {
    [protocolHandler bufferTextByte: byte];
    return [MUTerminalCSIState state];
  }
  else
  {
    [protocolHandler bufferTextByte: byte];
    return [MUTerminalTextState state];
  }
}

@end
