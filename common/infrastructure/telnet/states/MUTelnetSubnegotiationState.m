//
// MUTelnetSubnegotiationState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetSubnegotiationState.h"

#import "MUTelnetSubnegotiationIACState.h"

@implementation MUTelnetSubnegotiationState

- (MUTelnetState *) parse: (uint8_t) byte
       forConnectionState: (MUMUDConnectionState *) connectionState
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
