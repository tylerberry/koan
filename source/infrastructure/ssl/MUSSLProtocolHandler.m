//
//  MUSSLProtocolHandler.m
//  Koan
//
//  Created by Tyler Berry on 10/8/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import "MUSSLProtocolHandler.h"

@implementation MUSSLProtocolHandler

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
  [protocolStack preprocessOutputByte: byte previousProtocolHandler: self];
}


@end
