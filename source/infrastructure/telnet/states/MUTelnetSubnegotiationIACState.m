//
// MUTelnetSubnegotiationIACState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetSubnegotiationIACState.h"

#import "MUTelnetSubnegotiationState.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetSubnegotiationIACState

+ (id) stateWithReturnState: (Class) state
{
  return [[[self alloc] initWithReturnState: state] autorelease];
}

- (id) initWithReturnState: (Class) state
{
  if (!(self = [super init]))
    return nil;
  
  returnState = state;
  
  return self;
}

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case MUTelnetEndSubnegotiation:
      [protocolHandler handleBufferedSubnegotiation];
      return [MUTelnetTextState state];

    case MUTelnetInterpretAsCommand:
      [protocolHandler bufferSubnegotiationByte: byte];
      return [returnState state];

    default:
      [protocolHandler log: @"Telnet irregularity: IAC %u while in subnegotiation.", byte];
      return [returnState state];
  }
}

@end
