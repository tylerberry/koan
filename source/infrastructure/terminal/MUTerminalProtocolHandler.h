//
// MUTerminalProtocolHandler.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUProtocolHandler.h"

#import "MUMUDConnectionState.h"

@interface MUTerminalProtocolHandler : MUProtocolHandler

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

@end
