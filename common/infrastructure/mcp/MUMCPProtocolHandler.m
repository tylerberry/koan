//
// MUMCPProtocolHandler.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMCPProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

typedef NS_ENUM (NSInteger, MCPState)
{
  MUMCPStateNewLine,
  MUMCPStateReceivedHash,
  MUMCPStateReceivedHashDollar,
  MUMCPStatePassThrough,
  MUMCPStateBeginCommand,
  MUMCPStateBufferCommand,
  MUMCPStateBufferMultilineValue,
  MUMCPStateEndMultilineValue,
};

@interface MUMCPProtocolHandler ()
{
  MUMUDConnectionState *_connectionState;
  
  MCPState _mcpState;
}

- (void) _bufferMCPByte: (uint8_t) byte;
- (void) _finalizeMultilineValue;
- (void) _handleCommand;
- (void) _handleMultilineValue;

@end

#pragma mark -

@implementation MUMCPProtocolHandler

@synthesize delegate;

+ (instancetype) protocolHandlerWithConnectionState: (MUMUDConnectionState *) connectionState
{
  return [[self alloc] initWithConnectionState: connectionState];
}

- (instancetype) initWithConnectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = connectionState;
  _mcpState = MUMCPStateNewLine;
  
  return self;
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  switch (_mcpState)
  {
    case MUMCPStateNewLine:
      if (byte == '#')
        _mcpState = MUMCPStateReceivedHash;
      else
      {
        if (byte != '\n')
          _mcpState = MUMCPStatePassThrough;
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPStateReceivedHash:
      if (byte == '$')
        _mcpState = MUMCPStateReceivedHashDollar;
      else
      {
        if (byte == '\n')
          _mcpState = MUMCPStateNewLine;
        else
          _mcpState = MUMCPStatePassThrough;
        PASS_ON_PARSED_BYTE ('#');
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPStateReceivedHashDollar:
      if (byte == '#')
        _mcpState = MUMCPStateBeginCommand;
      else if (byte == '"')
        _mcpState = MUMCPStatePassThrough;
      else
      {
        if (byte == '\n')
          _mcpState = MUMCPStateNewLine;
        else
          _mcpState = MUMCPStatePassThrough;
        PASS_ON_PARSED_BYTE ('#');
        PASS_ON_PARSED_BYTE ('$');
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPStatePassThrough:
      if (byte == '\n')
        _mcpState = MUMCPStateNewLine;
      PASS_ON_PARSED_BYTE (byte);
      break;
      
    case MUMCPStateBeginCommand:
      if (byte == '*')
        _mcpState = MUMCPStateBufferMultilineValue;
      else if (byte == ':')
        _mcpState = MUMCPStateEndMultilineValue;
      else
      {
        _mcpState = MUMCPStateBufferCommand;
        [self _bufferMCPByte: byte];
      }
      break;
      
    case MUMCPStateBufferCommand:
      if (byte == '\n')
      {
        _mcpState = MUMCPStateNewLine;
        [self _handleCommand];
      }
      else
        [self _bufferMCPByte: byte];
      break;
      
    case MUMCPStateBufferMultilineValue:
      if (byte == '\n')
      {
        _mcpState = MUMCPStateNewLine;
        [self _handleMultilineValue];
      }
      else
        [self _bufferMCPByte: byte];
      break;
      
    case MUMCPStateEndMultilineValue:
      if (byte == '\n')
      {
        _mcpState = MUMCPStateNewLine;
        [self _finalizeMultilineValue];
      }
      else
        [self _bufferMCPByte: byte];
      break;
  }
}

- (void) reset
{
  _mcpState = MUMCPStateNewLine;
}

#pragma mark - Private methods

- (void) _bufferMCPByte: (uint8_t) byte
{
  return;
}

- (void) _finalizeMultilineValue
{
  return;
}

- (void) _handleCommand
{
  return;
}

- (void) _handleMultilineValue
{
  return;
}

@end
