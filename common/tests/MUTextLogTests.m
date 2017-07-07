//
// MUTextLogTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLog.h"

@interface MUTextLogTests : XCTestCase

@end

#pragma mark -

@implementation MUTextLogTests

- (void) setUp
{
  [super setUp];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testExtractingOneHeader
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Foo: Bar\n\nText"];
  
  XCTAssertEqualObjects (log.headers[@"Foo"], @"Bar");
}

- (void) testExtractThreeHeaders
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Foo: Bar\nBaz: Quux\nDate: 01-01-2001\n\nText"];
  
  XCTAssertEqualObjects (log.headers[@"Foo"], @"Bar");
  XCTAssertEqualObjects (log.headers[@"Baz"], @"Quux");
  XCTAssertEqualObjects (log.headers[@"Date"], @"01-01-2001");
}

- (void) testContentAfterHeaders
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Header: Value\nHeader2: Value\n\nBody: text\nIs cool\n"];
  
  XCTAssertEqualObjects (log.content, @"Body: text\nIs cool\n");
}

- (void) testHeadersWithoutColon
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Foo\nBar\n\nBaz"];
  
  XCTAssertNil (log.content);
  XCTAssertNil (log.headers);
}

- (void) testTrimLeadingAndTrailingSpaces
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Header:  Value  \n\nText"];  
  XCTAssertEqualObjects (log.headers[@"Header"], @"Value");
}

@end
