//
// MUTerminalProtocolHandler.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

@implementation MUTerminalProtocolHandler
{
  MUMUDConnectionState *_connectionState;
}

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithConnectionState: telnetConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;

  return self;
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  //[_telnetStateMachine parse: byte forProtocolHandler: self];
  
  PASS_ON_PARSED_BYTE (byte);
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
