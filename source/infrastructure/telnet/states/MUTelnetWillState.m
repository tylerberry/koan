//
// MUTelnetWillState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetWillState.h"

#import "MUTelnetTextState.h"

@implementation MUTelnetWillState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC WILL %@.", [protocolHandler optionNameForByte: byte]];
  [protocolHandler receivedWill: byte];
  return [MUTelnetTextState state];
}

@end
