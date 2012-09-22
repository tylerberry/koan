//
// MUMCPProtocolHandler.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUMCPProtocolHandler.h"

@implementation MUMCPProtocolHandler

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithStack: stack connectionState: telnetConnectionState];
}

- (id) initWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super initWithStack: stack]))
    return nil;
  
  connectionState = telnetConnectionState;
  
  return self;
}


- (NSObject <MUMCPProtocolHandlerDelegate> *) delegate
{
  return delegate;
}

- (void) setDelegate: (NSObject <MUMCPProtocolHandlerDelegate> *) object
{
  delegate = object;
}

#pragma mark - MUByteProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  [protocolStack parseInputByte: byte previousProtocolHandler: self];
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
  [protocolStack preprocessOutputByte: byte previousProtocolHandler: self];
}

@end
