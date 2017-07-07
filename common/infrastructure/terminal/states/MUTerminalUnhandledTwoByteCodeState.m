//
// MUTerminalUnhandledTwoByteCodeState.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalUnhandledTwoByteCodeState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalUnhandledTwoByteCodeState
{
  uint8_t _firstByte;
}

+ (instancetype) stateWithFirstByte: (uint8_t) firstByte
{
  return [[self alloc] initWithFirstByte: firstByte];
}

- (instancetype) initWithFirstByte: (uint8_t) firstByte
{
  if (!(self = [super init]))
    return nil;

  _firstByte = firstByte;

  return self;
}

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Terminal: Unimplemented code: ESC %c %c (%02u/%02u %02u/%02u).",
                        _firstByte, byte, _firstByte / 16, _firstByte % 16, byte / 16, byte % 16];

  return [MUTerminalTextState state];
}

@end
