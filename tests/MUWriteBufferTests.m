//
// MUWriteBufferTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWriteBufferTests.h"
#import "MUWriteBuffer.h"

@interface MUWriteBufferTests ()
{
  MUWriteBuffer *_buffer;
  NSMutableData *_output;
}

- (NSString *) outputString;
- (void) assertOutputAfterFlushIsString: (NSString *) string;

@end

#pragma mark -

@implementation MUWriteBufferTests

- (void) setUp
{
  _buffer = [MUWriteBuffer buffer];
  _buffer.byteDestination = self;
  _output = [NSMutableData data];
}

- (void) tearDown
{
  _buffer = nil;
  _output = nil;
}

- (void) testWriteNil
{
  [_buffer appendString: nil];
  [self assertOutputAfterFlushIsString: @""];
}

- (void) testWriteMultipleTimes
{
  [_buffer appendString: @"foo"];
  [_buffer appendString: @"bar"];
  [self assertOutputAfterFlushIsString: @"foobar"];
}

- (void) testWriteMultipleTimesWithInterspersedNil
{
  [_buffer appendString: @"foo"];
  [_buffer appendString: nil];
  [_buffer appendString: @"bar"];
  [self assertOutputAfterFlushIsString: @"foobar"];
}

- (void) testClearBufferAndWrite
{
  [_buffer appendString: @"foo"];
  [_buffer clear];
  [self assertOutputAfterFlushIsString: @""];
}

- (void) testClearBufferThenAddMoreAndWrite
{
  [_buffer appendString: @"foo"];
  [_buffer clear];
  [_buffer appendString: @"bar"];
  [self assertOutputAfterFlushIsString: @"bar"];
}

#ifdef TYLER_WILL_FIX
- (void) testRemoveLastCharacterAndWrite
{
  [_buffer appendString: @"foop"];
  [_buffer removeLastCharacter];
  [self assertOutputAfterFlushIsString: @"foo"];
}
#endif

- (void) testWriteAll
{
  [_buffer appendString: @"foo"];
  [self assertOutputAfterFlushIsString: @"foo"];
}

- (void) testWriteLine
{
  [_buffer appendLine: @"foo"];
  [self assertOutputAfterFlushIsString: @"foo\n"];
}

- (void) testWriteBytesWithPriority
{
  [_buffer appendString: @"foo"];
  [_buffer writeDataWithPriority: [NSData dataWithBytes: (uint8_t *) "ab" length: 2]];
  [self assert: [self outputString] equals: @"ab"];
  [_buffer flush];
  [self assert: [self outputString] equals: @"abfoo"];
}

#pragma mark - MUByteDestination protocol

- (void) write: (NSData *) data
{
  [_output appendData: data];
}

#pragma mark - Private methods

- (void) assertOutputAfterFlushIsString: (NSString *) string
{
  [_buffer flush];
  [self assert: [self outputString] equals: string];
}

- (NSString *) outputString
{
  return [[NSString alloc] initWithData: _output encoding: NSASCIIStringEncoding];
}

@end
