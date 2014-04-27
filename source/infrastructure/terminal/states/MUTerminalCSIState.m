//
// MUTerminalCSIState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalCSIState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalCSIState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case 0x20 ... 0x2f: // Intermediate bytes.
    case 0x30 ... 0x3f: // Parameter bytes.
      [protocolHandler bufferCommandByte: byte];
      return self;

    case 0x40 ... 0x7f: // Final bytes.
      [protocolHandler processCSIWithFinalByte: byte];
      return [MUTerminalTextState state];

    default:
      [protocolHandler bufferCommandByte: byte];
      [protocolHandler bufferTextByte: byte];
      return [MUTerminalTextState state];
  }
}

@end
