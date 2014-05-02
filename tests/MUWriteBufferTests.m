//
// MUWriteBufferTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUByteDestination.h"
#import "MUWriteBuffer.h"

@interface MUWriteBufferTests : XCTestCase <MUByteDestination>

- (NSString *) _outputString;
- (void) _assertOutputAfterFlushIsString: (NSString *) string;

@end

#pragma mark -

@implementation MUWriteBufferTests
{
  MUWriteBuffer *_buffer;
  NSMutableData *_output;
}

- (void) setUp
{
  [super setUp];
  _buffer = [MUWriteBuffer buffer];
  _buffer.byteDestination = self;
  _output = [NSMutableData data];
}

- (void) tearDown
{
  _buffer = nil;
  _output = nil;
  [super tearDown];
}

- (void) testWriteNil
{
  [_buffer appendString: nil];
  [self _assertOutputAfterFlushIsString: @""];
}

- (void) testWriteMultipleTimes
{
  [_buffer appendString: @"foo"];
  [_buffer appendString: @"bar"];
  [self _assertOutputAfterFlushIsString: @"foobar"];
}

- (void) testWriteMultipleTimesWithInterspersedNil
{
  [_buffer appendString: @"foo"];
  [_buffer appendString: nil];
  [_buffer appendString: @"bar"];
  [self _assertOutputAfterFlushIsString: @"foobar"];
}

- (void) testClearBufferAndWrite
{
  [_buffer appendString: @"foo"];
  [_buffer clear];
  [self _assertOutputAfterFlushIsString: @""];
}

- (void) testClearBufferThenAddMoreAndWrite
{
  [_buffer appendString: @"foo"];
  [_buffer clear];
  [_buffer appendString: @"bar"];
  [self _assertOutputAfterFlushIsString: @"bar"];
}

#ifdef TYLER_WILL_FIX
- (void) testRemoveLastCharacterAndWrite
{
  [_buffer appendString: @"foop"];
  [_buffer removeLastCharacter];
  [self _assertOutputAfterFlushIsString: @"foo"];
}
#endif

- (void) testWriteAll
{
  [_buffer appendString: @"foo"];
  [self _assertOutputAfterFlushIsString: @"foo"];
}

- (void) testWriteLine
{
  [_buffer appendLine: @"foo"];
  [self _assertOutputAfterFlushIsString: @"foo\n"];
}

- (void) testWriteBytesWithPriority
{
  [_buffer appendString: @"foo"];
  [_buffer writeDataWithPriority: [NSData dataWithBytes: (uint8_t *) "ab" length: 2]];
  XCTAssertEqualObjects ([self _outputString], @"ab");
  [_buffer flush];
  XCTAssertEqualObjects ([self _outputString], @"abfoo");
}

#pragma mark - MUByteDestination protocol

- (void) write: (NSData *) data
{
  [_output appendData: data];
}

#pragma mark - Private methods

- (void) _assertOutputAfterFlushIsString: (NSString *) string
{
  [_buffer flush];
  XCTAssertEqualObjects ([self _outputString], string);
}

- (NSString *) _outputString
{
  return [[NSString alloc] initWithData: _output encoding: NSASCIIStringEncoding];
}

@end
