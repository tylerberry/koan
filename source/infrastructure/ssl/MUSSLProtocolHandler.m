//
//  MUSSLProtocolHandler.m
//  Koan
//
//  Created by Tyler Berry on 10/8/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import "MUSSLProtocolHandler.h"

#include "openssl/bio.h"
#include "openssl/ssl.h"
#include "openssl/err.h"

@implementation MUSSLProtocolHandler

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) newConnectionState
{
  return [[self alloc] initWithStack: stack connectionState: newConnectionState];
}

- (id) initWithStack: (MUProtocolStack *) stack connectionState: (MUMUDConnectionState *) newConnectionState
{
  if (!(self = [super initWithStack: stack]))
    return nil;
  
  connectionState = newConnectionState;
  
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
