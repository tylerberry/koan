//
// MUTerminalProtocolHandler.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUTerminalStateMachine.h"

#define DEBUG_LOG_TERMINAL 1

@implementation MUTerminalProtocolHandler
{
  MUMUDConnectionState *_connectionState;
  MUTerminalStateMachine *_terminalStateMachine;

  NSMutableData *_commandBuffer;
}

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithConnectionState: telnetConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;

  _terminalStateMachine = [MUTerminalStateMachine stateMachine];

  _commandBuffer = [[NSMutableData alloc] init];

  return self;
}

#pragma mark - MUTerminalProtocolHandler protocol

- (void) bufferCommandByte: (uint8_t) byte
{
  [_commandBuffer appendBytes: &byte length: 1];
}

- (void) bufferTextByte: (uint8_t) byte
{
  PASS_ON_PARSED_BYTE (byte);
}

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);

  [self.delegate log: message arguments: args];

  va_end (args);
}

- (void) processCommandStringWithType: (enum MUTerminalControlStringTypes) commandStringType
{
  switch (commandStringType)
  {
    case MUTerminalControlStringTypeOperatingSystemCommand:
#ifdef DEBUG_LOG_TERMINAL
      [self log: @"Terminal: OSC %@", _commandBuffer];
#endif
      break;

    case MUTerminalControlStringTypePrivacyMessage:
#ifdef DEBUG_LOG_TERMINAL
      [self log: @"Terminal: PM %@", _commandBuffer];
#endif
      break;

    case MUTerminalControlStringTypeApplicationProgram:
#ifdef DEBUG_LOG_TERMINAL
      [self log: @"Terminal: AP %@", _commandBuffer];
#endif
      break;

  }
  _commandBuffer.data = [NSData data];
}

- (void) processCSIWithFinalByte: (uint8_t) finalByte
{
#ifdef DEBUG_LOG_TERMINAL
  uint8_t bytes[_commandBuffer.length + 1];

  [_commandBuffer getBytes: bytes];
  bytes[_commandBuffer.length] = 0x00;

  [self log: @"Terminal: CSI %s%c [%02u/%02u]", bytes, finalByte, finalByte / 16, finalByte % 16];
#endif

  _commandBuffer.data = [NSData data];
}

- (void) processPseudoANSIMusic
{
#ifdef DEBUG_LOG_TERMINAL
  [self log: @"Terminal: Pseudo-ANSI Music %@", _commandBuffer];
#endif

  _commandBuffer.data = [NSData data];
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  [_terminalStateMachine parse: byte forProtocolHandler: self];
}

- (void) preprocessByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (byte);
}

- (void) preprocessFooterData: (NSData *) data
{
  PASS_ON_PREPROCESSED_FOOTER_DATA (data);
}


@end
