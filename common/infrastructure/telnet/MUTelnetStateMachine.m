//
// MUTelnetStateMachine.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetStateMachine.h"

#import "MUTelnetTextState.h"

@interface MUTelnetStateMachine ()

@property (assign) BOOL telnetConfirmed;

@end

#pragma mark -

@implementation MUTelnetStateMachine

+ (instancetype) stateMachine
{
  return [[self alloc] init];
}

- (instancetype) init
{
  if (!(self = [super init]))
    return nil;
  
  _state = [MUTelnetTextState state];
  _telnetConfirmed = NO;
  
  return self;
}

- (void) confirmTelnet
{
  self.telnetConfirmed = YES;
}

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  self.state = [self.state parse: byte forStateMachine: self protocolHandler: protocolHandler];
}

- (void) reset
{
  self.state = [MUTelnetTextState state];
  self.telnetConfirmed = NO;
}

@end
