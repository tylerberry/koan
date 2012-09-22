//
// MUTelnetDoState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetDoState.h"

#import "MUTelnetOption.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetDoState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC DO %@.", [MUTelnetOption optionNameForByte: byte]];
  [protocolHandler receivedDo: byte];
  return [MUTelnetTextState state];
}

@end
