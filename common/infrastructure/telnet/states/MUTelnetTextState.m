//
// MUTelnetTextState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetTextState.h"

#import "MUTelnetIACState.h"

@implementation MUTelnetTextState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  if (byte == MUTelnetInterpretAsCommand)
    return [MUTelnetIACState state];
  else
  {
    [protocolHandler bufferTextByte: byte];
    return self;
  }
}

@end
