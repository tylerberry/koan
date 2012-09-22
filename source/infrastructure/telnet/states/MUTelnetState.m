//
// MUTelnetState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetConstants.h"
#import "MUTelnetState.h"
#import "MUByteSet.h"

static NSMutableDictionary *states;

@implementation MUTelnetState

+ (id) state
{
  MUTelnetState *result;
  
  if (!states)
    states = [[NSMutableDictionary alloc] init];
  
  if (![states objectForKey: [self description]])
  {
    result = [[self alloc] init];
    [states setObject: result forKey: [self description]];
  }
  else
    result = [states objectForKey: [self description]];
  
  return result;
}

+ (MUByteSet *) telnetCommandBytes
{
  return [MUByteSet byteSetWithBytes:
    MUTelnetEndOfRecord,
    MUTelnetEndSubnegotiation,
    MUTelnetNoOperation,
    MUTelnetDataMark,
    MUTelnetBreak,
    MUTelnetInterruptProcess,
    MUTelnetAbortOutput,
    MUTelnetAreYouThere,
    MUTelnetEraseCharacter,
    MUTelnetEraseLine,
    MUTelnetGoAhead,
    MUTelnetBeginSubnegotiation,
    MUTelnetWill,
    MUTelnetWont,
    MUTelnetDo,
    MUTelnetDont,
    MUTelnetInterpretAsCommand,
    -1];
}

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocol
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -[parse:forStateMachine:protocol]"
                               userInfo: nil];
}

@end
