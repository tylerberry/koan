//
// MUByteSet.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUByteSet.h"

@implementation MUByteSet

+ (id) byteSet
{
  return [[self alloc] init];
}

+ (id) byteSetWithBytes: (const uint8_t) firstByte, ...
{
  va_list args;
  va_start (args, firstByte);
  id result = [[self alloc] initWithFirstByte: firstByte remainingBytes: args];
  va_end (args);
  return result;
}

+ (id) byteSetWithBytes: (const uint8_t * const) bytes length: (size_t) length
{
  return [[self alloc] initWithBytes: bytes length: length];
}

- (void) addByte: (const uint8_t) byte;
{
  if (!contains[byte])
    contains[byte] = YES;
}

- (void) addBytes: (const uint8_t) firstByte, ...
{
  va_list args;
  va_start (args, firstByte);
  [self addFirstByte: firstByte remainingBytes: args];
  va_end (args);
}

- (void) addFirstByte: (const uint8_t) firstByte remainingBytes: (va_list) bytes
{
  int current;

  [self addByte: firstByte];
  while ((current = va_arg (bytes, int)) != -1)
    contains[current] = YES;  
}

- (BOOL) containsByte: (const uint8_t) byte
{
  return contains[byte];
}

- (NSData *) dataValue
{
  NSMutableData *result = [NSMutableData data];
  uint8_t byte[1];

  for (uint16_t i = 0; i <= UINT8_MAX; i++)
  {
    if (contains[i])
    {
      byte[0] = (uint8_t) i;
      [result appendBytes: byte length: 1];
    }
  }
  return result;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  for (NSUInteger i = 0; i <= UINT8_MAX; i++)
    contains[i] = NO;
  
  return self;
}

- (id) initWithBytes: (const uint8_t * const) bytes length: (size_t) length
{
  if (![self init])
    return nil;
  
  for (NSUInteger i = 0; i < length; i++)
    [self addByte: bytes[i]];
  
  return self;
}

- (id) initWithFirstByte: (const uint8_t) firstByte remainingBytes: (va_list) bytes
{
  if (![self init])
    return nil;

  [self addFirstByte: firstByte remainingBytes: bytes];
  
  return self;
}

- (MUByteSet *) inverseSet
{
  MUByteSet *set = [MUByteSet byteSet];
  
  for (NSUInteger i = 0; i <= UINT8_MAX; i++)
    set->contains[i] = !contains[i];
  
  return set;
}

- (void) removeByte: (const uint8_t) byte
{
  contains[byte] = NO;
}

@end
