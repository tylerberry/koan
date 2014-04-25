//
// MUTerminalProtocolHandler.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUProtocolHandler.h"

#import "MUMUDConnectionState.h"

@protocol MUTerminalProtocolHandler

- (void) bufferTextByte: (uint8_t) byte;

@end

#pragma mark -

@interface MUTerminalProtocolHandler : MUProtocolHandler <MUTerminalProtocolHandler>

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

@end
