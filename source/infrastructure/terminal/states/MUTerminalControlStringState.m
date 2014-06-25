//
// MUTerminalControlStringState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalControlStringState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalControlStringState
{
  enum MUTerminalControlStringTypes _controlStringType;
}

+ (instancetype) stateWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType
{
  return [[self alloc] initWithControlStringType: controlStringType];
}

- (instancetype) initWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType
{
  if (!(self = [super init]))
    return nil;

  _controlStringType = controlStringType;

  return self;
}

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case 0x08 ... 0x0d:
    case 0x20 ... 0x7e:
      [protocolHandler bufferCommandByte: byte];
      return self;

    case 0x07: // ASCII BEL, in common use (by XTerm et al) to end Control String commands.
    case 0x9c: // String Terminator, ECMA-48 standard terminator for a valid Control String command.
      [protocolHandler processCommandStringWithType: _controlStringType];
      return [MUTerminalTextState state];

    default:
      // TODO: Invalid, need to determine what we can do here. Probably have to revert to text.
      [protocolHandler bufferCommandByte: byte];
      [protocolHandler bufferTextByte: byte];
      return self;
  }
}


@end
