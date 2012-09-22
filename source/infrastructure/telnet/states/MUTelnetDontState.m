//
// MUTelnetDontState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetDontState.h"

#import "MUTelnetOption.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetDontState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC DONT %@.", [MUTelnetOption optionNameForByte: byte]];
  [protocolHandler receivedDont: byte];
  return [MUTelnetTextState state];
}

@end
