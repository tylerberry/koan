//
// MUTerminalProtocolHandler.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUTerminalStateMachine.h"

@implementation MUTerminalProtocolHandler
{
  MUMUDConnectionState *_connectionState;
  MUTerminalStateMachine *_terminalStateMachine;
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

  return self;
}

#pragma mark - MUTerminalProtocolHandler protocol

- (void) bufferCommandByte: (uint8_t) byte
{
  return;
}

- (void) bufferTextByte: (uint8_t) byte
{
  PASS_ON_PARSED_BYTE (byte);
}

- (void) processCommandStringWithType: (enum MUTerminalControlStringTypes) commandStringType
{
  return;
}

- (void) processCSIWithFinalByte: (uint8_t) finalByte
{
  return;
}

- (void) processPseudoANSIMusic
{
  return;
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
