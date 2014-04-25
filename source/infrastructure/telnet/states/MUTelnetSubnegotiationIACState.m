//
// MUTelnetSubnegotiationIACState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetSubnegotiationIACState.h"

#import "MUTelnetSubnegotiationState.h"
#import "MUTelnetTextState.h"

@implementation MUTelnetSubnegotiationIACState
{
  Class _returnState;
}

+ (id) stateWithReturnState: (Class) state
{
  return [[self alloc] initWithReturnState: state];
}

- (id) initWithReturnState: (Class) state
{
  if (!(self = [super init]))
    return nil;
  
  _returnState = state;
  
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
      return [_returnState state];

    default:
      [protocolHandler log: @"  Telnet: IAC %u while in subnegotiation.", byte];
      return [_returnState state];
  }
}

@end
