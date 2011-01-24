//
// MUSOCKS5MethodSelection.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUSOCKS5MethodSelection.h"
#import "MUWriteBuffer.h"
#import "MUByteSource.h"

@implementation MUSOCKS5MethodSelection

+ (id) socksMethodSelection
{
  return [[[MUSOCKS5MethodSelection alloc] init] autorelease];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  methods = [[NSMutableData alloc] init];
  [self addMethod: MUSOCKS5NoAuthentication];
  
  return self;
}

- (void) dealloc
{
  [methods release];
  [super dealloc];
}

- (void) addMethod: (MUSOCKS5Method) method
{
  char bytes[1] = {method};
  [methods appendBytes: bytes length: 1];
}

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer
{
  const uint8_t *bytes;
  
  [buffer appendByte: MUSOCKS5Version];
  [buffer appendByte: [methods length]];
  bytes = [methods bytes];
  
  for (unsigned i = 0; i < [methods length]; i++)
    [buffer appendByte: bytes[i]];
}

- (MUSOCKS5Method) method
{
  return selectedMethod;
}

- (void) parseResponseFromByteSource: (NSObject <MUByteSource> *) byteSource
{
  NSData *reply = [byteSource readExactlyLength: 2];
  if ([reply length] != 2)
    return;
  selectedMethod = ((uint8_t *) [reply bytes])[1];    
}

@end
