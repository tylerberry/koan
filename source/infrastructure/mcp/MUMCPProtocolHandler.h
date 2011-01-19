//
// MUMCPProtocolHandler.h
//
// Copyright (c) 2010 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "J3Protocol.h"
#import "J3TelnetConnectionState.h"

@protocol MUMCPProtocolHandlerDelegate;

@interface MUMCPProtocolHandler : J3ByteProtocolHandler
{
  J3TelnetConnectionState *connectionState;
  NSObject <MUMCPProtocolHandlerDelegate> *delegate;
}

+ (id) protocolHandlerWithStack: (J3ProtocolStack *) stack connectionState: (J3TelnetConnectionState *) telnetConnectionState;
- (id) initWithStack: (J3ProtocolStack *) stack connectionState: (J3TelnetConnectionState *) telnetConnectionState;

- (NSObject <MUMCPProtocolHandlerDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUMCPProtocolHandlerDelegate> *) object;

@end

#pragma mark -

@protocol MUMCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
