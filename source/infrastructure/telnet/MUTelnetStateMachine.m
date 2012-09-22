//
// MUTelnetStateMachine.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetStateMachine.h"

#import "MUTelnetTextState.h"

@implementation MUTelnetStateMachine

@synthesize state, telnetConfirmed;

+ (id) stateMachine
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  self.state = [MUTelnetTextState state];
  self.telnetConfirmed = NO;
  
  return self;
}

- (void) confirmTelnet
{
  self.telnetConfirmed = YES;
}

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  self.state = [state parse: byte forStateMachine: self protocolHandler: protocolHandler];
}

@end
