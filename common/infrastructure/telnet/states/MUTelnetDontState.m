//
// MUTelnetDontState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetDontState.h"

#import "MUTelnetOption.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetDontState

- (MUTelnetState *) parse: (uint8_t) byte
       forConnectionState: (MUMUDConnectionState *) connectionState
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC DONT %@.", [MUTelnetOption optionNameForByte: byte]];
  [protocolHandler receivedDont: byte];
  return [MUTelnetTextState state];
}

@end
