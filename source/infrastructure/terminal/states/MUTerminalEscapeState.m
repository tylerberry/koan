//
// MUTerminalEscapeState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalEscapeState.h"

#import "MUTerminalConstants.h"
#import "MUTerminalControlStringState.h"
#import "MUTerminalCSIFirstByteState.h"
#import "MUTerminalDesignateOtherCodingSystemState.h"
#import "MUTerminalTextState.h"
#import "MUTerminalUnhandledTwoByteCodeState.h"

@implementation MUTerminalEscapeState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case 0x25: // Designate Other Coding System
      return [MUTerminalDesignateOtherCodingSystemState state];

    // These are all C1-esque terminal codes that take an extra byte, and which we don't handle.

    case 0x20: // ' ': Set 7-bit mode, 8-bit mode, or ANSI conformance level
    case 0x23: // '#': Various DEC terminal line sizing commands
    case 0x28: // '(': Designate G0 Character Set (ISO-2022 or VT100)
    case 0x29: // ')': Designate G1 Character Set (ISO-2022 or VT100)
    case 0x2a: // '*': Designate G2 Character Set (ISO-2022 or VT100)
    case 0x2b: // '+': Designate G3 Character Set (ISO-2022 or VT100)
    case 0x2d: // '-': Designate G1 Character Set (VT300)
    case 0x2e: // '.': Designate G2 Character Set (VT300)
    case 0x2f: // '/': Designate G3 Character Set (VT300)
      return [MUTerminalUnhandledTwoByteCodeState stateWithFirstByte: byte];

    // These are all valid C1 codes which we don't handle.

    case 0x40: // Padding Character
    case 0x41: // High Octet Preset
    case 0x42: // Break Permitted Here
    case 0x43: // No Break Here
    case 0x44: // Index
    case 0x45: // Next Line
    case 0x46: // Start Of Selected Area (also, for some HP terminals, cursor reset to lower left)
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
      [protocolHandler log: @"Terminal: Unimplemented C1: ESC %02u/%02u.", byte / 16, byte % 16];
      return [MUTerminalTextState state];

    // These are all unimplemented C1-esque codes which we don't handle.

    case 0x36: // '6': Back Index
    case 0x37: // '7': Save Cursor
    case 0x38: // '8': Restore Cursor
    case 0x39: // '9': Forward Index
    case 0x3d: // '=': Application Keypad
    case 0x3e: // '>': Normal Keypad
    case 0x63: // 'c': Full Reset
    case 0x6c: // 'l': Memory Lock
    case 0x6d: // 'm': Memory Unlock
    case 0x6e: // 'n': Invoke G2 Character Set As GL
    case 0x6f: // 'o': Invoke G3 Character Set As GL
    case 0x7c: // '|': Invoke G3 Character Set As GR
    case 0x7d: // '}': Invoke G2 Character Set As GR
    case 0x7e: // '~': Invoke G1 Character Set As GR
      [protocolHandler log: @"Terminal: Unimplemented code: ESC %02u/%02u.", byte / 16, byte % 16];
      return [MUTerminalTextState state];

    case 0x5b: // Control Sequence Introducer
      return [MUTerminalCSIFirstByteState state];

    case 0x5d: // Operating System Command
      return [MUTerminalControlStringState stateWithControlStringType: MUTerminalControlStringTypeOperatingSystemCommand];

    case 0x5e: // Privacy Message
      return [MUTerminalControlStringState stateWithControlStringType: MUTerminalControlStringTypePrivacyMessage];

    case 0x5f: // Application Program
      return [MUTerminalControlStringState stateWithControlStringType: MUTerminalControlStringTypeApplicationProgram];

    default:
      [protocolHandler log: @"Terminal: Unrecognized C1 code: ESC %02u/%02u", byte / 16, byte % 16];
      return [MUTerminalTextState state];
  }
}

@end
