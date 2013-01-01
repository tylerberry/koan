//
// MUWriteBuffer.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUWriteBuffer

- (void) appendByte: (uint8_t) byte;
- (void) appendCharacter: (unichar) character;
- (void) appendData: (NSData *) data;
- (void) appendLine: (NSString *) line;
- (void) appendString: (NSString *) string;
- (void) clear;
- (void) flush;
- (BOOL) isEmpty;
- (NSUInteger) length;
- (void) writeDataWithPriority: (NSData *) data;

// Both of these are pretty expensive in MUWriteBuffer currently.
- (NSData *) dataValue;
- (NSString *) stringValue;

@end

#pragma mark -

@interface MUWriteBufferException : NSException

@end

#pragma mark -

@protocol MUByteDestination;

@interface MUWriteBuffer : NSObject <MUWriteBuffer>
{
  NSObject <MUByteDestination> *destination;
  
  NSMutableArray *blocks;
  id lastBlock;
  BOOL lastBlockIsBinary;
  NSUInteger totalLength;
}

+ (id) buffer;

- (void) setByteDestination: (NSObject <MUByteDestination> *) object;

@end
