//
// MUTelnetState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetConstants.h"
#import "MUTelnetState.h"
#import "MUByteSet.h"

static NSMutableDictionary *states;

@implementation MUTelnetState

+ (instancetype) state
{
  MUTelnetState *result;

  // TODO: This is probably not thread-safe.
  
  if (!states)
    states = [[NSMutableDictionary alloc] init];
  
  if (!states[self.description])
  {
    result = [[self alloc] init];
    states[self.description] = result;
  }
  else
    result = states[self.description];
  
  return result;
}

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocol
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -parse:forStateMachine:protocol:."
                               userInfo: nil];
}

@end
