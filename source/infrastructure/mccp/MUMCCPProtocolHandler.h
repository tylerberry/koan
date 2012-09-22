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
  NSObject <MUMCCPProtocolHandlerDelegate> *delegate;
  
  z_stream *stream;
  
  uint8_t *inbuf;
  unsigned inalloc;
  unsigned insize;
  
  uint8_t *outbuf;
  unsigned outalloc;
  unsigned outsize;
}

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState;
- (id) initWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState;

- (NSObject <MUMCCPProtocolHandlerDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUMCCPProtocolHandlerDelegate> *) object;

@end

#pragma mark -

@protocol MUMCCPProtocolHandlerDelegate

- (void) log: (NSString *) message arguments: (va_list) args;

@end
