//
// MUTerminalProtocolHandler.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUProtocolHandler.h"

#import "MUMUDConnectionState.h"
#import "MUProfile.h"
#import "MUTerminalConstants.h"

@protocol MUTerminalProtocolHandler

- (void) bufferCommandByte: (uint8_t) byte;
- (void) bufferTextByte: (uint8_t) byte;

- (void) handleBackspace;

- (void) setStringEncoding: (NSStringEncoding) stringEncoding;

- (void) log: (NSString *) message, ...;

- (void) processCommandStringWithType: (MUTerminalControlStringType) commandStringType;
- (void) processCSIWithFinalByte: (uint8_t) finalByte;
- (void) processPseudoANSIMusic;

@end

#pragma mark -

@protocol MUTerminalProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end

#pragma mark -

@interface MUTerminalProtocolHandler : MUProtocolHandler <MUTerminalProtocolHandler>

@property (weak) NSObject <MUTerminalProtocolHandlerDelegate> *delegate;
@property (readonly) NSDictionary *textAttributes;

+ (instancetype) protocolHandlerWithProfile: (MUProfile *) profile
                            connectionState: (MUMUDConnectionState *) connectionState;
- (instancetype) initWithProfile: (MUProfile *) profile
                 connectionState: (MUMUDConnectionState *) connectionState;

@end
