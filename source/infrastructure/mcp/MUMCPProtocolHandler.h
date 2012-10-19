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
{
  MUMUDConnectionState *connectionState;
}

@property (weak, nonatomic) NSObject <MUMCPProtocolHandlerDelegate> *delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

@end

#pragma mark -

@protocol MUMCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
