//
// MUTelnetNotTelnetState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetNotTelnetState.h"

@implementation MUTelnetNotTelnetState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  // If we've decided we're not dealing with Telnet, just pass everything on as text, forever.
  
  [protocolHandler bufferTextByte: byte];
  return self;
}

@end
