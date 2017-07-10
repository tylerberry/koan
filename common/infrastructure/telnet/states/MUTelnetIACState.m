//
// MUTelnetIACState.m
//
// Copyright (c) 2013 3James Software.
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

@interface MUTelnetIACState ()

- (MUTelnetState *) _notTelnetFromByte: (uint8_t) byte
                       protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;

@end

#pragma mark -

@implementation MUTelnetIACState

- (MUTelnetState *) parse: (uint8_t) byte
       forConnectionState: (MUMUDConnectionState *) connectionState
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  switch (byte)
  {
    case MUTelnetNoOperation:
      connectionState.telnetConfirmed = YES;
      return [MUTelnetTextState state];

    // TODO: Handle these valid commands individually.

    case MUTelnetDataMark:
    case MUTelnetBreak:
    case MUTelnetInterruptProcess:
    case MUTelnetAbortOutput:
    case MUTelnetAreYouThere:
    case MUTelnetEraseLine:
      [protocolHandler log: @"  Telnet: IAC %u (unhandled).", byte];
      connectionState.telnetConfirmed = YES;
      return [MUTelnetTextState state];

    case MUTelnetEraseCharacter:
      connectionState.telnetConfirmed = YES;
      [protocolHandler deleteLastBufferedCharacter];
      return [MUTelnetTextState state];
      
    case MUTelnetGoAhead:
      connectionState.telnetConfirmed = YES;
      [protocolHandler useBufferedDataAsPrompt];
      return [MUTelnetTextState state];
    
    case MUTelnetEndOfRecord:
      if (!connectionState.telnetConfirmed)
      {
        [protocolHandler log: @"  Telnet: IAC EOR without receiving earlier telnet sequences."];
        return [self _notTelnetFromByte: byte protocolHandler: protocolHandler];
      }
      
      [protocolHandler useBufferedDataAsPrompt];
      return [MUTelnetTextState state];
      
    case MUTelnetWill:
      connectionState.telnetConfirmed = YES;
      return [MUTelnetWillState state];
      
    case MUTelnetWont:
      connectionState.telnetConfirmed = YES;
      return [MUTelnetWontState state];
      
    case MUTelnetDo:
      connectionState.telnetConfirmed = YES;
      return [MUTelnetDoState state];
      
    case MUTelnetDont:
      connectionState.telnetConfirmed = YES;
      return [MUTelnetDontState state];
      
    case MUTelnetInterpretAsCommand:
      [protocolHandler bufferTextByte: MUTelnetInterpretAsCommand];
      return [MUTelnetTextState state];

    case MUTelnetBeginSubnegotiation:
      if (!connectionState.telnetConfirmed)
      {
        [protocolHandler log: @"  Telnet: IAC SB without receiving earlier telnet sequences."];
        
        // Ideally we would like to take the action below - drop into a non-telnet state if this awful violation of the
        // telnet spec happens. Unfortunately, there are some MUDs that do send IAC SB without having negotiated any
        // options, and it happens before any other data is sent from the MUD, so there's no possibility of detecting it
        // in advance.
        //
        // Technically it would still be RFC-correct to go non-telnet here, but it would harm functionality.
        
        // return [self notTelnetFromByte: byte forStateMachine: stateMachine protocolHandler: protocolHandler];
      }
      
      return [MUTelnetSubnegotiationOptionState state];
      
    case MUTelnetEndSubnegotiation:
    default:
      if (!connectionState.telnetConfirmed)
      {
        [protocolHandler log: @"  Telnet: IAC SE without receiving earlier telnet sequences."];
        return [self _notTelnetFromByte: byte protocolHandler: protocolHandler];
      }
      
      [protocolHandler log: @"  Telnet: IAC SE while not in subnegotiation."];
      return [MUTelnetTextState state];
  }
}

#pragma mark - Private methods

- (MUTelnetState *) _notTelnetFromByte: (uint8_t) byte
                       protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler bufferTextByte: MUTelnetInterpretAsCommand];
  [protocolHandler bufferTextByte: byte];
  return [MUTelnetNotTelnetState state];
}

@end

