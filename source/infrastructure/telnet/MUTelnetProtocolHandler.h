//
// MUTelnetProtocolHandler.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetConstants.h"
#import "MUTelnetOption.h"

@class MUTelnetState;
@class MUTelnetStateMachine;
@protocol MUWriteBuffer;

#pragma mark -

@protocol MUTelnetProtocolHandler

- (void) bufferSubnegotiationByte: (uint8_t) byte;
- (void) handleBufferedSubnegotiation;

- (void) bufferTextByte: (uint8_t) byte;
- (void) useBufferedDataAsPrompt;

- (void) sendNAWSSubnegotiationWithNumberOfLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns;

- (void) log: (NSString *) message, ...;

- (void) receivedDo: (uint8_t) option;
- (void) receivedDont: (uint8_t) option;
- (void) receivedWill: (uint8_t) option;
- (void) receivedWont: (uint8_t) option;

@end

#pragma mark -

@protocol MUTelnetProtocolHandlerDelegate

@required
- (void) enableTLS;
- (void) log: (NSString *) message arguments: (va_list) args;
- (void) reportWindowSizeToServer;

@end

#pragma mark -

@interface MUTelnetProtocolHandler : MUProtocolHandler <MUTelnetProtocolHandler, MUTelnetOptionDelegate>
{
  MUTelnetStateMachine *stateMachine;
  
  NSMutableData *subnegotiationBuffer;
  
  MUTelnetOption *options[TELNET_OPTION_MAX + 1];
  BOOL receivedCR;
  BOOL optionRequestSent;
}

@property (weak) NSObject <MUTelnetProtocolHandlerDelegate> *delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

// Option negotation.

- (void) resetOptionStates;

- (void) disableOptionForHim: (uint8_t) option;
- (void) disableOptionForUs: (uint8_t) option;
- (void) enableOptionForHim: (uint8_t) option;
- (void) enableOptionForUs: (uint8_t) option;
- (BOOL) optionYesForHim: (uint8_t) option;
- (BOOL) optionYesForUs: (uint8_t) option;- (void) shouldAllowDo: (BOOL) value forOption: (uint8_t) option;
- (void) shouldAllowWill: (BOOL) value forOption: (uint8_t) option;

@end
