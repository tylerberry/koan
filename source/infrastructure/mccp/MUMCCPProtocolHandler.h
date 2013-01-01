//
// MUMCCPProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"

@protocol MUMCCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end

#pragma mark -

@interface MUMCCPProtocolHandler : MUProtocolHandler

@property (weak) NSObject <MUMCCPProtocolHandlerDelegate> *delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) connectionState;

@end
