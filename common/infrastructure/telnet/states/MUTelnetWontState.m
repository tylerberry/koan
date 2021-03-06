//
// MUTelnetWontState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetWontState.h"

#import "MUTelnetOption.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetWontState

- (MUTelnetState *) parse: (uint8_t) byte
       forConnectionState: (MUMUDConnectionState *) connectionState
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC WONT %@.", [MUTelnetOption optionNameForByte: byte]];
  [protocolHandler receivedWont: byte];
  return [MUTelnetTextState state];
}

@end
