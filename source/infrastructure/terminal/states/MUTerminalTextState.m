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
  switch (byte)
  {
    case 0x00: // Null.
      [protocolHandler bufferTextByte: byte];
      return self;

    case 0x01: // Start Of Heading.
    case 0x02: // Start Of Text.
    case 0x03: // End Of Text.
    case 0x04: // End Of Transmission.
    case 0x05: // Enquiry.
    case 0x06: // Acknowledge.
      [protocolHandler bufferTextByte: byte];
      return self;

    case 0x07: // Bell.
    case 0x08: // Backspace.
    case 0x09: // Horizontal Tabulation.
    case 0x0b: // Vertical Tabulation.
    case 0x0c: // Form Feed.
    case 0x0e: // Shift Out. (To alternate character set.)
    case 0x0f: // Shift In.
    case 0x10: // Data Link Escape.
    case 0x11: // Device Control 1 (XON).
    case 0x12: // Device Control 2.
    case 0x13: // Device Control 3 (XOFF).
    case 0x14: // Device Control 4.
    case 0x15: // Negative Acknowledge.
    case 0x16: // Synchronous Idle.
    case 0x17: // End Of Transmission Block.
    case 0x18: // Cancel.
    case 0x19: // End Of Medium.
    case 0x1a: // Substitute.
    case 0x1c: // File Separator.
    case 0x1d: // Group Separator.
    case 0x1e: // Record Separator.
    case 0x1f: // Unit Separator.
      [protocolHandler bufferTextByte: byte];
      return self;

    case 0x1b: // Escape.
      [protocolHandler bufferTextByte: byte];
      return [MUTerminalEscapeState state];

    case 0x0a: // Line Feed.
    case 0x0d: // Carriage Return.
    default:
      [protocolHandler bufferTextByte: byte];
      return self;
  }
}

@end
