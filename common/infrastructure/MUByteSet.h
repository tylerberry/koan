//
// MUByteSet.h
//
// Copyright (c) 2013 3James Software.
//

@interface MUByteSet : NSObject 
{
  BOOL contains[UINT8_MAX];
}

+ (instancetype) byteSet;
+ (instancetype) byteSetWithBytes: (const unsigned int) firstByte, ...;
+ (instancetype) byteSetWithBytes: (const uint8_t * const) bytes length: (size_t) length;

- (instancetype) initWithBytes: (const uint8_t * const) bytes length: (size_t) length;
- (instancetype) initWithFirstByte: (const uint8_t) first remainingBytes: (va_list) bytes;

- (void) addByte: (const uint8_t) byte;
- (void) addBytes: (const unsigned int) firstByte, ...;
- (void) addFirstByte: (const uint8_t) firstByte remainingBytes: (va_list) bytes;
- (BOOL) containsByte: (const uint8_t) byte;
- (NSData *) dataValue;
- (MUByteSet *) inverseSet;
- (void) removeByte: (const uint8_t) byte;

@end
