//
// MUTelnetWillState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetWillState.h"

#import "MUTelnetOption.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetWillState

- (MUTelnetState *) parse: (uint8_t) byte
       forConnectionState: (MUMUDConnectionState *) connectionState
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC WILL %@.", [MUTelnetOption optionNameForByte: byte]];
  [protocolHandler receivedWill: byte];
  return [MUTelnetTextState state];
}

@end
