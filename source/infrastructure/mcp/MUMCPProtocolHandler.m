//
// MUMCPProtocolHandler.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUMCPProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

enum MCPStates
{
  MUMCPNewLineState,
  MUMCPReceivedHashState,
  MUMCPReceivedHashDollarState,
  MUMCPPassThroughState,
  MUMCPBufferMCPCommandState
};

@interface MUMCPProtocolHandler ()
{
  MUMUDConnectionState *_connectionState;
  
  enum MCPStates _mcpState;
}

- (void) bufferMCPByte: (uint8_t) byte;
- (void) handleBufferedMCPMessage;

@end

#pragma mark -

@implementation MUMCPProtocolHandler

@synthesize delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState
{
  return [[self alloc] initWithConnectionState: connectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = connectionState;
  _mcpState = MUMCPNewLineState;
  
  return self;
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  switch (_mcpState)
  {
    case MUMCPNewLineState:
      if (byte == '#')
        _mcpState = MUMCPReceivedHashState;
      else
      {
        if (byte != '\n')
          _mcpState = MUMCPPassThroughState;
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPReceivedHashState:
      if (byte == '$')
        _mcpState = MUMCPReceivedHashDollarState;
      else
      {
        if (byte == '\n')
          _mcpState = MUMCPNewLineState;
        else
          _mcpState = MUMCPPassThroughState;
        PASS_ON_PARSED_BYTE ('#');
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPReceivedHashDollarState:
      if (byte == '#')
        _mcpState = MUMCPBufferMCPCommandState;
      else if (byte == '"')
        _mcpState = MUMCPPassThroughState;
      else
      {
        if (byte == '\n')
          _mcpState = MUMCPNewLineState;
        else
          _mcpState = MUMCPPassThroughState;
        PASS_ON_PARSED_BYTE ('#');
        PASS_ON_PARSED_BYTE ('$');
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPPassThroughState:
      if (byte == '\n')
        _mcpState = MUMCPNewLineState;
      PASS_ON_PARSED_BYTE (byte);
      break;
      
    case MUMCPBufferMCPCommandState:
      if (byte == '\n')
      {
        _mcpState = MUMCPNewLineState;
        [self handleBufferedMCPMessage];
      }
      else
        [self bufferMCPByte: byte];
      break;
  }
}

#pragma mark - Private methods

- (void) bufferMCPByte: (uint8_t) byte
{
  return;
}

- (void) handleBufferedMCPMessage
{
  return;
}

@end
