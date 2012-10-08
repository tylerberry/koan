//
// MUTelnetSubnegotiationOptionState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetSubnegotiationOptionState.h"

#import "MUTelnetMCCP1SubnegotiationState.h"
#import "MUTelnetSubnegotiationIACState.h"
#import "MUTelnetSubnegotiationState.h"

@implementation MUTelnetSubnegotiationOptionState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case MUTelnetInterpretAsCommand:
      [protocolHandler log: @"  Telnet: IAC received immediately after IAC SB."];
      return [MUTelnetSubnegotiationIACState stateWithReturnState: [MUTelnetSubnegotiationOptionState class]];
      
    case MUTelnetOptionMCCP1:
      [protocolHandler bufferSubnegotiationByte: byte];
      return [MUTelnetMCCP1SubnegotiationState state];
      
    default:
      [protocolHandler bufferSubnegotiationByte: byte];
      return [MUTelnetSubnegotiationState state];
  }
}

@end
