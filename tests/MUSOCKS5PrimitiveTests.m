//
// MUSOCKS5PrimitiveTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUSOCKS5PrimitiveTests.h"

#import "MUByteSource.h"
#import "MUReadBuffer.h"
#import "MUSOCKS5Authentication.h"
#import "MUSOCKS5Constants.h"
#import "MUSOCKS5MethodSelection.h"
#import "MUSOCKS5Request.h"
#import "MUWriteBuffer.h"

@interface MUMockByteSource : MUReadBuffer <MUByteSource>

+ (id) mockByteSource;

@end

#pragma mark -

@implementation MUMockByteSource

+ (id) mockByteSource
{
  return [[MUMockByteSource alloc] init];
}

- (void) appendBytes: (const uint8_t *) bytes length: (unsigned) length
{
  [self appendData: [NSData dataWithBytes: bytes length: length]];
}

- (NSUInteger) availableBytes
{
  return self.length;
}

- (BOOL) hasDataAvailable
{
  return self.availableBytes > 0;
}

- (void) poll
{
  return;
}

- (NSData *) readExactlyLength: (size_t) length;
{
  return [self readUpToLength: length];
}

- (NSData *) readUpToLength: (size_t) length
{
  return [self dataByConsumingBytesToIndex: length];
}

@end

#pragma mark -

@interface MUSOCKS5PrimitiveTests ()

- (void) assertObject: (id) selection writes: (NSString *) output;

@end

#pragma mark -

@implementation MUSOCKS5PrimitiveTests

- (void) setUp
{
  buffer = [[MUWriteBuffer alloc] init];
}

- (void) tearDown
{
  return;
}

- (void) testMethodSelection
{
  MUSOCKS5MethodSelection *selection = [MUSOCKS5MethodSelection socksMethodSelection];
  const char expected1[] = {0x05, 0x01, 0x00};
  const char expected2[] = {0x05, 0x02, 0x00, 0x02};
  
  [buffer clear];
  [selection appendToBuffer: buffer];
  
  NSString *output = buffer.stringValue;
  for (unsigned i = 0; i < buffer.length; i++)
  {
    XCTAssertEqual ([output characterAtIndex: i], expected1[i]);
  }

  [selection addMethod: MUSOCKS5UsernamePassword];

  [buffer clear];
  [selection appendToBuffer: buffer];
  output = buffer.stringValue;
  for (unsigned j = 0; j < buffer.length; j++)
  {
    XCTAssertEqual ([output characterAtIndex: j], expected2[j]);
  }
}

- (void) testSelectMethod
{
  MUSOCKS5MethodSelection *selection = [MUSOCKS5MethodSelection socksMethodSelection];
  MUMockByteSource *source = [MUMockByteSource mockByteSource];
  
  [selection addMethod: MUSOCKS5UsernamePassword];
  XCTAssertEqual (selection.selectedMethod, MUSOCKS5NoAuthentication);

  [source appendBytes: (uint8_t *) "\x05\x02" length: 2];
  [selection parseResponseFromByteSource: source];
  XCTAssertEqual (selection.selectedMethod, MUSOCKS5UsernamePassword);
}

- (void) testRequest
{
  MUSOCKS5Request *request = [MUSOCKS5Request socksRequestWithHostname: @"example.com" port: 0xABCD];
  uint8_t expected[18] = {MUSOCKS5Version, MUSOCKS5Connect, 0, 3, 11, 'e', 'x', 'a', 'm', 'p', 'l', 'e', '.', 'c', 'o', 'm', 0xAB, 0xCD};
  
  [buffer clear];
  [request appendToBuffer: buffer];
  
  NSData *data = buffer.dataValue;
  XCTAssertEqual (data.length, (NSUInteger) 18); // same as expected length above
  for (unsigned i = 0; i < 18; i++)
  {
    XCTAssertEqual (((uint8_t *) data.bytes)[i], expected[i]);
  }
}

- (void) testReplyWithDomainName
{
  MUSOCKS5Request *request = [MUSOCKS5Request socksRequestWithHostname: @"example.com" port: 0xABCD];
  MUMockByteSource *source = [MUMockByteSource mockByteSource];
  uint8_t reply[18] = {MUSOCKS5Version, MUSOCKS5ConnectionNotAllowed, 0, MUSOCKS5DomainName, 11, 'e', 'x', 'a', 'm', 'p', 'l', 'e', '.', 'c', 'o', 'm', 0xAB, 0xCD};
  
  XCTAssertEqual (request.reply, MUSOCKS5NoReply);
  [source appendBytes: reply length: 18];
  [source appendBytes: (uint8_t *) "foo" length: 3];
  [request parseReplyFromByteSource: source];
  
  NSString *readString = source.ASCIIStringByConsumingBuffer;
  XCTAssertEqualObjects (readString, @"foo");
  XCTAssertEqual (request.reply, MUSOCKS5ConnectionNotAllowed);
}

- (void) testReplyWithIPV4
{
  MUSOCKS5Request *request = [MUSOCKS5Request socksRequestWithHostname: @"example.com" port: 0xABCD];
  MUMockByteSource *source = [MUMockByteSource mockByteSource];
  uint8_t reply[10] = {MUSOCKS5Version, MUSOCKS5ConnectionNotAllowed, 0, MUSOCKS5IPv4, 10, 1, 2, 3, 0xAB, 0xCD};
  
  XCTAssertEqual (request.reply, MUSOCKS5NoReply);
  [source appendBytes: reply length: 10];
  [source appendBytes: (uint8_t *) "foo" length: 3];
  [request parseReplyFromByteSource: source];
  
  NSString *readString = source.ASCIIStringByConsumingBuffer;
  XCTAssertEqualObjects (readString, @"foo");
  XCTAssertEqual (request.reply, MUSOCKS5ConnectionNotAllowed);
}

- (void) testReplyWithIPV6
{
  MUSOCKS5Request *request = [MUSOCKS5Request socksRequestWithHostname: @"example.com" port: 0xABCD];
  MUMockByteSource *source = [MUMockByteSource mockByteSource];
  uint8_t reply[22] = {MUSOCKS5Version, MUSOCKS5ConnectionNotAllowed, 0, MUSOCKS5IPv6, 0xFE, 0xC0, 0x03, 0x04, 0x05,
    0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xAB, 0xCD};
  
  XCTAssertEqual (request.reply, MUSOCKS5NoReply);
  [source appendBytes: reply length: 22];
  [source appendBytes: (uint8_t *) "foo" length: 3];
  [request parseReplyFromByteSource: source];
  
  NSString *readString = source.ASCIIStringByConsumingBuffer;
  XCTAssertEqualObjects (readString, @"foo");
  XCTAssertEqual (request.reply, MUSOCKS5ConnectionNotAllowed);
}

- (void) testAuthentication
{
  MUSOCKS5Authentication *auth = [MUSOCKS5Authentication socksAuthenticationWithUsername: @"bob" password: @"barfoo"];
  uint8_t expected[12] = {MUSOCKS5UsernamePasswordVersion, 3, 'b', 'o', 'b', 6, 'b', 'a', 'r', 'f', 'o', 'o'};
  
  [buffer clear];
  [auth appendToBuffer: buffer];
  
  NSData *data = buffer.dataValue;
  XCTAssertEqual (data.length, (NSUInteger) 12); // same as expected length above
  for (unsigned i = 0; i < 12; i++)
  {
    XCTAssertEqual (((uint8_t *) data.bytes)[i], expected[i]);
  }
}

- (void) testAuthenticationReply
{
  MUSOCKS5Authentication *auth = [MUSOCKS5Authentication socksAuthenticationWithUsername: @"bob" password: @"barfoo"];
  MUMockByteSource *source = [MUMockByteSource mockByteSource];
  
  XCTAssertFalse (auth.authenticated);
  [source appendByte: 1];
  [source appendByte: 0];
  [auth parseReplyFromSource: source];
  XCTAssertTrue (auth.authenticated);
  [source appendByte: 1];
  [source appendByte: 11]; // non-zero
  [auth parseReplyFromSource: source];
  XCTAssertFalse (auth.authenticated);
}

#pragma mark - Private methods

- (void) assertObject: (id) object writes: (NSString *) output
{
  [buffer clear];
  [object appendToBuffer: buffer];
  XCTAssertEqualObjects (buffer.stringValue, output);
}

@end
