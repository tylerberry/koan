//
// MUTerminalStateMachine.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalStateMachine.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalStateMachine

+ (instancetype) stateMachine
{
  return [[self alloc] init];
}

- (instancetype) init
{
  if (!(self = [super init]))
    return nil;

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
