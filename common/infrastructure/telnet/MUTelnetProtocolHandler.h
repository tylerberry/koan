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

#pragma mark -

@protocol MUTelnetProtocolHandler

- (void) bufferSubnegotiationByte: (uint8_t) byte;
- (void) handleBufferedSubnegotiation;

- (void) bufferTextByte: (uint8_t) byte;
- (void) deleteLastBufferedCharacter;
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

@property (weak) NSObject <MUTelnetProtocolHandlerDelegate> *delegate;

+ (instancetype) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;
- (instancetype) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

// Option negotation.

- (void) disableOptionForHim: (uint8_t) option;
- (void) disableOptionForUs: (uint8_t) option;
- (void) enableOptionForHim: (uint8_t) option;
- (void) enableOptionForUs: (uint8_t) option;
- (BOOL) optionEnabledForHim: (uint8_t) option;
- (BOOL) optionEnabledForUs: (uint8_t) option;

@end
