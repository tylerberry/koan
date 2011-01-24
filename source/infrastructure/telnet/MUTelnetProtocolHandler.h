//
// MUTelnetProtocolHandler.h
//
// Copyright (c) 2011 3James Software.
//s

#import <Cocoa/Cocoa.h>
#import "MUByteProtocolHandler.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetConstants.h"
#import "MUTelnetOption.h"

@class MUTelnetState;
@class MUTelnetStateMachine;
@protocol MUTelnetProtocolHandlerDelegate;
@protocol MUWriteBuffer;

#pragma mark -

@protocol MUTelnetProtocolHandler

- (void) bufferSubnegotiationByte: (uint8_t) byte;
- (void) bufferTextByte: (uint8_t) byte;

- (void) handleBufferedSubnegotiation;
- (void) log: (NSString *) message, ...;
- (NSString *) optionNameForByte: (uint8_t) byte;

- (void) receivedDo: (uint8_t) option;
- (void) receivedDont: (uint8_t) option;
- (void) receivedWill: (uint8_t) option;
- (void) receivedWont: (uint8_t) option;

@end

#pragma mark -

@interface MUTelnetProtocolHandler : MUByteProtocolHandler <MUTelnetProtocolHandler, MUTelnetOptionDelegate>
{
  MUMUDConnectionState *connectionState;
  MUTelnetStateMachine *stateMachine;
  
  NSMutableData *subnegotiationBuffer;
  
  NSObject <MUTelnetProtocolHandlerDelegate> *delegate;
  MUTelnetOption *options[TELNET_OPTION_MAX];
  BOOL receivedCR;
  BOOL optionRequestSent;
}

@property (readonly) MUMUDConnectionState *connectionState;

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState;

- (NSObject <MUTelnetProtocolHandlerDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUTelnetProtocolHandlerDelegate> *) object;

// Option negotation.

- (void) disableOptionForHim: (uint8_t) option;
- (void) disableOptionForUs: (uint8_t) option;
- (void) enableOptionForHim: (uint8_t) option;
- (void) enableOptionForUs: (uint8_t) option;
- (BOOL) optionYesForHim: (uint8_t) option;
- (BOOL) optionYesForUs: (uint8_t) option;- (void) shouldAllowDo: (BOOL) value forOption: (uint8_t) option;
- (void) shouldAllowWill: (BOOL) value forOption: (uint8_t) option;

@end

#pragma mark -

@protocol MUTelnetProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;
- (void) writeDataToSocket: (NSData *) data;

@end
