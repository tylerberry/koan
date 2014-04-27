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

- (void) log: (NSString *) message, ...;

- (void) processCommandStringWithType: (enum MUTerminalControlStringTypes) commandStringType;
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

+ (id) protocolHandlerWithProfile: (MUProfile *) profile
                  connectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithProfile: (MUProfile *) profile
       connectionState: (MUMUDConnectionState *) telnetConnectionState;

@end
