//
// MUTerminalPseudoANSIMusicState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalPseudoANSIMusicState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalPseudoANSIMusicState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case 'a' ... 'g': // Valid bytes for pseudo-ANSI music compositions.
    case 'l' ... 'p':
    case 's':
    case 'A' ... 'G':
    case 'L' ... 'P':
    case 'S':
    case ' ':
    case '.':
    case '0' ... '9':
      [protocolHandler bufferCommandByte: byte];
      [protocolHandler bufferTextByte: byte];
      return self;

    case 0x0e: // Defined terminator for pseudo-ANSI music.
      [protocolHandler bufferTextByte: byte];
      [protocolHandler processPseudoANSIMusic];
      return [MUTerminalTextState state];

    default:
      [protocolHandler bufferCommandByte: byte];
      [protocolHandler bufferTextByte: byte];
      return [MUTerminalTextState state];
  }
}

@end
