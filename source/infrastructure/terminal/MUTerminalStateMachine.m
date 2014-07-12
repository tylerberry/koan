//
// MUTerminalStateMachine.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalStateMachine.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalStateMachine

+ (instancetype) stateMachineWithConnectionState: (MUMUDConnectionState *) connectionState
{
  return [[self alloc] initWithConnectionState: connectionState];
}

- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;

  _connectionState = connectionState;
  _state = [MUTerminalTextState state];

  return self;
}

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  self.state = [self.state parse: byte forStateMachine: self protocolHandler: protocolHandler];
}

- (void) reset
{
  self.state = [MUTerminalTextState state];
}

@end
