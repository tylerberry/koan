//
// MUTextLogTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLogTests.h"
#import "MUTextLog.h"

#pragma mark -

@implementation MUTextLogTests

- (void) setUp
{
  return;
}

- (void) tearDown
{
  return;
}

- (void) testExtractingOneHeader
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Foo: Bar\n\nText"];
  
  [self assert: log.headers[@"Foo"] equals: @"Bar"];
}

- (void) testExtractThreeHeaders
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Foo: Bar\nBaz: Quux\nDate: 01-01-2001\n\nText"];
  
  [self assert: log.headers[@"Foo"] equals: @"Bar"];
  [self assert: log.headers[@"Baz"] equals: @"Quux"];
  [self assert: log.headers[@"Date"] equals: @"01-01-2001"];
}

- (void) testContentAfterHeaders
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Header: Value\nHeader2: Value\n\nBody: text\nIs cool\n"];
  
  [self assert: log.content equals: @"Body: text\nIs cool\n"];
}

- (void) testHeadersWithoutColon
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Foo\nBar\n\nBaz"];
  
  [self assertNil: log.content];
  [self assertNil: log.headers];
}

- (void) testTrimLeadingAndTrailingSpaces
{
  MUTextLog *log = [[MUTextLog alloc] initWithString: @"Header:  Value  \n\nText"];  
  [self assert: log.headers[@"Header"] equals: @"Value"];
}

@end
