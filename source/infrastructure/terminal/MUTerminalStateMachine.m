//
//  MUTerminalStateMachine.m
//  Koan
//
//  Created by Tyler Berry on 4/24/14.
//  Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalStateMachine.h"

#import "MUTerminalState.h"

@implementation MUTerminalStateMachine

+ (id) stateMachine
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;

  _state = [MUTerminalState state];

  return self;
}

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  self.state = [self.state parse: byte forStateMachine: self protocolHandler: protocolHandler];
}

@end
