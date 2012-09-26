//
// MUMCPProtocolHandler.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUMCPProtocolHandler.h"

enum MCPStates
{
  MUMCPNewLineState,
  MUMCPReceivedHashState,
  MUMCPReceivedHashDollarState,
  MUMCPPassThroughState,
  MUMCPBufferMCPCommandState
};

@interface MUMCPProtocolHandler ()

@property (assign) enum MCPStates mcpState;

- (void) bufferMCPByte: (uint8_t) byte;
- (void) handleBufferedMCPMessage;

@end

#pragma mark -

@implementation MUMCPProtocolHandler

@synthesize delegate;

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithStack: stack connectionState: telnetConnectionState];
}

- (id) initWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super initWithStack: stack]))
    return nil;
  
  connectionState = telnetConnectionState;
  self.mcpState = MUMCPNewLineState;
  
  return self;
}

#pragma mark - MUByteProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  switch (self.mcpState)
  {
    case MUMCPNewLineState:
      if (byte == '#')
        self.mcpState = MUMCPReceivedHashState;
      else
      {
        if (byte != '\n')
          self.mcpState = MUMCPPassThroughState;
        [protocolStack parseInputByte: byte previousProtocolHandler: self];
      }
      break;
      
    case MUMCPReceivedHashState:
      if (byte == '$')
        self.mcpState = MUMCPReceivedHashDollarState;
      else
      {
        if (byte == '\n')
          self.mcpState = MUMCPNewLineState;
        else
          self.mcpState = MUMCPPassThroughState;
        [protocolStack parseInputByte: '#' previousProtocolHandler: self];
        [protocolStack parseInputByte: byte previousProtocolHandler: self];
      }
      break;
      
    case MUMCPReceivedHashDollarState:
      if (byte == '#')
        self.mcpState = MUMCPBufferMCPCommandState;
      else if (byte == '"')
        self.mcpState = MUMCPPassThroughState;
      else
      {
        if (byte == '\n')
          self.mcpState = MUMCPNewLineState;
        else
          self.mcpState = MUMCPPassThroughState;
        [protocolStack parseInputByte: '#' previousProtocolHandler: self];
        [protocolStack parseInputByte: '$' previousProtocolHandler: self];
        [protocolStack parseInputByte: byte previousProtocolHandler: self];
      }
      break;
      
    case MUMCPPassThroughState:
      if (byte == '\n')
        self.mcpState = MUMCPNewLineState;
      [protocolStack parseInputByte: byte previousProtocolHandler: self];
      break;
      
    case MUMCPBufferMCPCommandState:
      if (byte == '\n')
      {
        self.mcpState = MUMCPNewLineState;
        [self handleBufferedMCPMessage];
      }
      else
        [self bufferMCPByte: byte];
      break;
  }
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
