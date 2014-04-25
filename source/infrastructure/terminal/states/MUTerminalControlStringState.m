//
//  MUTerminalControlStringState.m
//  Koan
//
//  Created by Tyler Berry on 4/25/14.
//  Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalControlStringState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalControlStringState
{
  enum MUTerminalControlStringTypes _controlStringType;
}

+ (id) stateWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType
{
  return [[self alloc] initWithControlStringType: controlStringType];
}

- (id) initWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType
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
      [protocolHandler bufferTextByte: byte];
      return self;

    case 0x9c: // String terminator, ends a valid OSC command.
      [protocolHandler bufferTextByte: byte];
      [protocolHandler processOSCCommand];
      NSLog (@"Terminal: Valid OSC sequence");
      return [MUTerminalTextState state];

    default:
      // Invalid, need to determine what we can do here. Probably have to revert to text.
      [protocolHandler bufferCommandByte: byte];
      [protocolHandler bufferTextByte: byte];
      return self;
  }
}


@end
