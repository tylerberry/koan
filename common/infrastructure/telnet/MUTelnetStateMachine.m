//
// MUTelnetStateMachine.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetStateMachine.h"

#import "MUTelnetTextState.h"
@implementation MUTelnetStateMachine
{
  MUMUDConnectionState *_connectionState;
}

+ (instancetype) stateMachineWithConnectionState: (MUMUDConnectionState *) connectionState
{
  return [[self alloc] initWithConnectionState: connectionState];
}

- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = connectionState;
  _state = [MUTelnetTextState state];
  
  return self;
}

- (void) confirmTelnet
{
  _connectionState.telnetConfirmed = YES;
}

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  self.state = [self.state parse: byte forConnectionState: _connectionState protocolHandler: protocolHandler];
}

- (void) reset
{
  self.state = [MUTelnetTextState state];
}

@end
