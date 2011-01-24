//
// MUTelnetMCCP1SubnegotiationState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetMCCP1SubnegotiationState.h"

#import "MUTelnetSubnegotiationIACState.h"

@implementation MUTelnetMCCP1SubnegotiationState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case MUTelnetWill:
      return [MUTelnetSubnegotiationIACState stateWithReturnState: [MUTelnetMCCP1SubnegotiationState class]];
  
    case MUTelnetInterpretAsCommand:
      [protocolHandler log: @"Telnet irregularity: Received IAC while subnegotiating %@ option; expected WILL.", [protocolHandler optionNameForByte: MUTelnetOptionMCCP1]];
      return [MUTelnetSubnegotiationIACState stateWithReturnState: [MUTelnetMCCP1SubnegotiationState class]];

    default:
      [protocolHandler bufferTextByte: byte];
      return self;
  }
}
@end
