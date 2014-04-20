//
// MUSOCKS5MethodSelection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUSOCKS5MethodSelection.h"
#import "MUWriteBuffer.h"
#import "MUByteSource.h"

@implementation MUSOCKS5MethodSelection
{
  NSMutableData *_methods;
}

+ (id) socksMethodSelection
{
  return [[MUSOCKS5MethodSelection alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _methods = [[NSMutableData alloc] init];
  [self addMethod: MUSOCKS5NoAuthentication];
  
  return self;
}

- (void) addMethod: (MUSOCKS5Method) method
{
  char bytes[1] = {method};
  [_methods appendBytes: bytes length: 1];
}

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer
{
  [buffer appendByte: MUSOCKS5Version];
  [buffer appendByte: (uint8_t) _methods.length];  // Potentially loses precision.
  
  const uint8_t *bytes = _methods.bytes;
  
  for (unsigned i = 0; i < _methods.length; i++)
    [buffer appendByte: bytes[i]];
}

- (MUSOCKS5Method) method
{
  return _selectedMethod;
}

- (void) parseResponseFromByteSource: (NSObject <MUByteSource> *) byteSource
{
  NSData *reply = [byteSource readExactlyLength: 2];
  
  if (reply.length != 2)
    return;
  
  _selectedMethod = ((uint8_t *) reply.bytes)[1];
}

@end
