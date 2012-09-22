//
// MUTelnetSubnegotiationState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetSubnegotiationState.h"

#import "MUTelnetSubnegotiationIACState.h"

@implementation MUTelnetSubnegotiationState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case MUTelnetInterpretAsCommand:
      return [MUTelnetSubnegotiationIACState stateWithReturnState: [MUTelnetSubnegotiationState class]];
      
    default:
      [protocolHandler bufferSubnegotiationByte: byte];
      return self;
  }
}

@end
