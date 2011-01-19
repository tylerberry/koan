//
// MUMCPProtocolHandler.m
//
// Copyright (c) 2010 3James Software.
//

#import "MUMCPProtocolHandler.h"

@implementation MUMCPProtocolHandler

+ (id) protocolHandlerWithStack: (J3ProtocolStack *) stack connectionState: (J3TelnetConnectionState *) telnetConnectionState
{
  return [[[self alloc] initWithStack: stack connectionState: telnetConnectionState] autorelease];
}

- (id) initWithStack: (J3ProtocolStack *) stack connectionState: (J3TelnetConnectionState *) telnetConnectionState
{
  if (!(self = [super initWithStack: stack]))
    return nil;
  
  connectionState = [telnetConnectionState retain];
  
  return self;
}

- (void) dealloc
{
  [connectionState release];
  [super dealloc];
}

- (NSObject <MUMCPProtocolHandlerDelegate> *) delegate
{
  return delegate;
}

- (void) setDelegate: (NSObject <MUMCPProtocolHandlerDelegate> *) object
{
  delegate = object;
}

#pragma mark -
#pragma mark J3ByteProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  [protocolStack parseByte: byte previousProtocolHandler: self];
}

- (NSData *) headerForPreprocessedData
{
  return nil;
}

- (NSData *) footerForPreprocessedData
{
  return nil;
}

- (void) preprocessByte: (uint8_t) byte
{
  // Outgoing MCP commands are sent independently.
  [protocolStack preprocessByte: byte previousProtocolHandler: self];
}

@end
