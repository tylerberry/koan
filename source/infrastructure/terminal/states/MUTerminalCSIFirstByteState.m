//
// MUTerminalCSIFirstByteState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalCSIFirstByteState.h"

#import "MUTerminalCSIState.h"
#import "MUTerminalPseudoANSIMusicState.h"
#import "MUTerminalTextState.h"

@implementation MUTerminalCSIFirstByteState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case 0x4d: // 'M': Used as a marker for non-standard, and ECMA-48 spec-violating, pseudo-ANSI music.
      [protocolHandler bufferCommandByte: byte];
      return [MUTerminalPseudoANSIMusicState state];

    case 0x20 ... 0x2f: // Intermediate bytes.
    case 0x30 ... 0x3f: // Parameter bytes.
      [protocolHandler bufferCommandByte: byte];
      return [MUTerminalCSIState state];

    case 0x40 ... 0x4c: // Final bytes.
    case 0x4e ... 0x7f:
      [protocolHandler processCSIWithFinalByte: byte];
      return [MUTerminalTextState state];

    default:
      [protocolHandler bufferCommandByte: byte];
      [protocolHandler bufferTextByte: byte];
      return [MUTerminalTextState state];
  }
}

@end
