//
// MUReadBuffer.h
//
// Copyright (c) 2013 3James Software.
//

@protocol MUReadBuffer

- (void) appendByte: (uint8_t) byte;
- (void) appendData: (NSData *) data;
- (void) clear;
- (BOOL) isEmpty;
- (NSUInteger) length;

- (NSData *) dataByConsumingBuffer;
- (NSData *) dataByConsumingBytesToIndex: (NSUInteger) index;
- (NSData *) dataValue;

- (NSString *) ASCIIStringByConsumingBuffer;
- (NSString *) ASCIIStringValue;

- (NSString *) stringByConsumingBufferWithEncoding: (NSStringEncoding) encoding;
- (NSString *) stringValueWithEncoding: (NSStringEncoding) encoding;

@end

#pragma mark -

@interface MUReadBuffer : NSObject <MUReadBuffer>
{
  NSMutableData *dataBuffer;
}

+ (instancetype) buffer;

@end
