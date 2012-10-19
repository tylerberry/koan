//
// MUMCCPProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUProtocolHandler.h"
#import "MUMUDConnectionState.h"

typedef struct z_stream_s z_stream;

@protocol MUMCCPProtocolHandlerDelegate;

@interface MUMCCPProtocolHandler : MUProtocolHandler
{
  MUMUDConnectionState *connectionState;
}

@property (weak) NSObject <MUMCCPProtocolHandlerDelegate> *delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState;

@end

#pragma mark -

@protocol MUMCCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
