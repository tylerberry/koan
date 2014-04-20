//
// MUByteSet.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUByteSet : NSObject 
{
  BOOL contains[UINT8_MAX];
}

+ (id) byteSet;
+ (id) byteSetWithBytes: (const uint8_t) firstByte, ...;
+ (id) byteSetWithBytes: (const uint8_t * const) bytes length: (size_t) length;

- (id) initWithBytes: (const uint8_t * const) bytes length: (size_t) length;
- (id) initWithFirstByte: (const uint8_t) first remainingBytes: (va_list) bytes;

- (void) addByte: (const uint8_t) byte;
- (void) addBytes: (const uint8_t) firstByte, ...;
- (void) addFirstByte: (const uint8_t) firstByte remainingBytes: (va_list) bytes;
- (BOOL) containsByte: (const uint8_t) byte;
- (NSData *) dataValue;
- (MUByteSet *) inverseSet;
- (void) removeByte: (const uint8_t) byte;

@end
