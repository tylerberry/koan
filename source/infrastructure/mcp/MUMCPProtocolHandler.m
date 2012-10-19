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

@property (assign) enum MCPStates mcpState;

- (void) bufferMCPByte: (uint8_t) byte;
- (void) handleBufferedMCPMessage;

@end

#pragma mark -

@implementation MUMCPProtocolHandler

@synthesize delegate;

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithConnectionState: telnetConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;
  
  connectionState = telnetConnectionState;
  self.mcpState = MUMCPNewLineState;
  
  return self;
}

#pragma mark - MUProtocolHandler overrides

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
        PASS_ON_PARSED_BYTE (byte);
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
        PASS_ON_PARSED_BYTE ('#');
        PASS_ON_PARSED_BYTE (byte);
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
        PASS_ON_PARSED_BYTE ('#');
        PASS_ON_PARSED_BYTE ('$');
        PASS_ON_PARSED_BYTE (byte);
      }
      break;
      
    case MUMCPPassThroughState:
      if (byte == '\n')
        self.mcpState = MUMCPNewLineState;
      PASS_ON_PARSED_BYTE (byte);
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
