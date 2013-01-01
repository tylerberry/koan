//
// MUMCPProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"

@protocol MUMCPProtocolHandlerDelegate;

@interface MUMCPProtocolHandler : MUProtocolHandler

@property (weak, nonatomic) NSObject <MUMCPProtocolHandlerDelegate> *delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) connectionState;

@end

#pragma mark -

@protocol MUMCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
