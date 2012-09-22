//
// MUTelnetWontState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetWontState.h"

#import "MUTelnetOption.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetWontState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC WONT %@.", [MUTelnetOption optionNameForByte: byte]];
  [protocolHandler receivedWont: byte];
  return [MUTelnetTextState state];
}

@end
