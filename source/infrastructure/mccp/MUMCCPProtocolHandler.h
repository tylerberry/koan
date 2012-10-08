//
// MUMCCPProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUByteProtocolHandler.h"
#import "MUMUDConnectionState.h"

typedef struct z_stream_s z_stream;

@protocol MUMCCPProtocolHandlerDelegate;

@interface MUMCCPProtocolHandler : MUByteProtocolHandler
{
  MUMUDConnectionState *connectionState;
}

@property (weak) NSObject <MUMCCPProtocolHandlerDelegate> *delegate;

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState;

@end

#pragma mark -

@protocol MUMCCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
