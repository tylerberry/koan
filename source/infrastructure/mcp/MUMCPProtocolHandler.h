//
// MUMCPProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUByteProtocolHandler.h"
#import "MUMUDConnectionState.h"

@protocol MUMCPProtocolHandlerDelegate;

@interface MUMCPProtocolHandler : MUByteProtocolHandler
{
  MUMUDConnectionState *connectionState;
  NSObject <MUMCPProtocolHandlerDelegate> *delegate;
}

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack
                connectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithStack: (MUProtocolStack *) stack
     connectionState: (MUMUDConnectionState *) telnetConnectionState;

- (NSObject <MUMCPProtocolHandlerDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUMCPProtocolHandlerDelegate> *) object;

@end

#pragma mark -

@protocol MUMCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
