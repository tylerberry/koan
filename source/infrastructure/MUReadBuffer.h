//
// MUReadBuffer.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUReadBuffer

- (void) appendByte: (uint8_t) byte;
- (void) appendData: (NSData *) data;
- (void) clear;
- (BOOL) isEmpty;
- (unsigned) length;

- (NSData *) dataByConsumingBuffer;
- (NSData *) dataByConsumingBytesToIndex: (unsigned) index;
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

+ (MUReadBuffer *) buffer;

@end
