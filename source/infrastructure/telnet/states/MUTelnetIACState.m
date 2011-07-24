//
// MUTelnetIACState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetIACState.h"

#import "MUTelnetDontState.h"
#import "MUTelnetDoState.h"
#import "MUTelnetNotTelnetState.h"
#import "MUTelnetState.h"
#import "MUTelnetSubnegotiationOptionState.h"
#import "MUTelnetTextState.h"
#import "MUTelnetWillState.h"
#import "MUTelnetWontState.h"

@interface MUTelnetIACState (Private)

- (MUTelnetState *) notTelnetFromByte: (uint8_t) byte
                      forStateMachine: (MUTelnetStateMachine *) stateMachine
                      protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;

@end

#pragma mark -

@implementation MUTelnetIACState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    // TODO: handle these valid commands individually.
    case MUTelnetNoOperation:
    case MUTelnetDataMark:
    case MUTelnetBreak:
    case MUTelnetInterruptProcess:
    case MUTelnetAbortOutput:
    case MUTelnetAreYouThere:
    case MUTelnetEraseCharacter:
    case MUTelnetEraseLine:
      [stateMachine confirmTelnet];
      return [MUTelnetTextState state];
      
    case MUTelnetGoAhead:
      [stateMachine confirmTelnet];
      [protocolHandler useBufferedDataAsPrompt];
      return [MUTelnetTextState state];
    
    case MUTelnetEndOfRecord:
      if (!stateMachine.telnetConfirmed)
      {
        [protocolHandler log: @"Not telnet: IAC EOR without receiving earlier telnet sequences."];
        return [self notTelnetFromByte: byte forStateMachine: stateMachine protocolHandler: protocolHandler];
      }
      
      [protocolHandler useBufferedDataAsPrompt];
      return [MUTelnetTextState state];
      
    case MUTelnetWill:
      [stateMachine confirmTelnet];
      return [MUTelnetWillState state];
      
    case MUTelnetWont:
      [stateMachine confirmTelnet];
      return [MUTelnetWontState state];
      
    case MUTelnetDo:
      [stateMachine confirmTelnet];
      return [MUTelnetDoState state];
      
    case MUTelnetDont:
      [stateMachine confirmTelnet];
      return [MUTelnetDontState state];
      
    case MUTelnetInterpretAsCommand:
      [protocolHandler bufferTextByte: MUTelnetInterpretAsCommand];
      return [MUTelnetTextState state];

    case MUTelnetBeginSubnegotiation:
      if (!stateMachine.telnetConfirmed)
      {
        [protocolHandler log: @"Not telnet: IAC SB without receiving earlier telnet sequences."];
        return [self notTelnetFromByte: byte forStateMachine: stateMachine protocolHandler: protocolHandler];
      }
      
      return [MUTelnetSubnegotiationOptionState state];
      
    case MUTelnetEndSubnegotiation:
    default:
      if (!stateMachine.telnetConfirmed)
      {
        [protocolHandler log: @"Not telnet: IAC SE without receiving earlier telnet sequences."];
        return [self notTelnetFromByte: byte forStateMachine: stateMachine protocolHandler: protocolHandler];
      }
      
      [protocolHandler log: @"Telnet irregularity: IAC SE while not in subnegotiation."];
      return [MUTelnetTextState state];
  }
}

@end

#pragma mark -

@implementation MUTelnetIACState (Private)

- (MUTelnetState *) notTelnetFromByte: (uint8_t) byte
                      forStateMachine: (MUTelnetStateMachine *) stateMachine
                      protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler bufferTextByte: MUTelnetInterpretAsCommand];
  [protocolHandler bufferTextByte: byte];
  return [MUTelnetNotTelnetState state];
}

@end

