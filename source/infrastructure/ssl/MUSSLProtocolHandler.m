//
//  MUSSLProtocolHandler.m
//  Koan
//
//  Created by Tyler Berry on 10/8/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import "MUSSLProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#include "openssl/bio.h"
#include "openssl/ssl.h"
#include "openssl/err.h"

@implementation MUSSLProtocolHandler

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) newConnectionState
{
  return [[self alloc] initWithConnectionState: newConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState
{
  if (!(self = [super init]))
    return nil;
  
  connectionState = newConnectionState;
  
  return self;
}

- (void) parseByte: (uint8_t) byte
{
  PASS_ON_PARSED_BYTE (byte);
}

- (void) preprocessByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (byte);
}


@end
