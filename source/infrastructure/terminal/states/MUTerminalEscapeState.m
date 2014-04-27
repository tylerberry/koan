//
// MUTerminalEscapeState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalEscapeState.h"

#import "MUTerminalConstants.h"
#import "MUTerminalControlStringState.h"
#import "MUTerminalCSIFirstByteState.h"
#import "MUTerminalTextState.h"

@implementation MUTerminalEscapeState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    // These are all valid C1 codes that we don't handle.

    case 0x40: // Padding Character
    case 0x41: // High Octet Preset
    case 0x42: // Break Permitted Here
    case 0x43: // No Break Here
    case 0x44: // Index
    case 0x45: // Next Line
    case 0x46: // Start Of Selected Area
    case 0x47: // End Of Selected Area
    case 0x48: // Character Tabulation Set
    case 0x49: // Character Tabulation With Justification
    case 0x4a: // Line Tabulation Set
    case 0x4b: // Partial Line Forward
    case 0x4c: // Partial Line Backward
    case 0x4d: // Reverse Line Feed
    case 0x4e: // Single Shift 2
    case 0x4f: // Single Shift 3
    case 0x50: // Device Control String <-- special format
    case 0x51: // Private Use 1
    case 0x52: // Private Use 2
    case 0x53: // Set Transmit State
    case 0x54: // Cancel Character <-- destructive backspace
    case 0x55: // Message Waiting
    case 0x56: // Start Of Protected Area
    case 0x57: // End Of Protected Area
    case 0x58: // Start Of String
    case 0x59: // Single Graphic Character Introducer
    case 0x5a: // Single Character Introducer <-- makes next character printed
    case 0x5c: // String Terminator
      [protocolHandler log: @"Terminal: Unimplemented C1 %02u/%02u", byte / 16, byte % 16];
      return [MUTerminalTextState state];

    case 0x5b: // Control Sequence Introducer.
      return [MUTerminalCSIFirstByteState state];

    case 0x5d:
      return [MUTerminalControlStringState stateWithControlStringType: MUTerminalControlStringTypeOperatingSystemCommand];

    case 0x5e:
      return [MUTerminalControlStringState stateWithControlStringType: MUTerminalControlStringTypePrivacyMessage];

    case 0x5f:
      return [MUTerminalControlStringState stateWithControlStringType: MUTerminalControlStringTypeApplicationProgram];

    default:
      [protocolHandler log: @"Terminal: Unrecognized C1 code: ESC %02u/%02u", byte / 16, byte % 16];
      return [MUTerminalTextState state];
  }
}

@end
