//
// MUTextLogDocumentTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTextLogDocumentTests.h"
#import "MUTextLogDocument.h"

@implementation MUTextLogDocumentTests

- (void) testExtractingOneHeader
{
  MUTextLogDocument *logDocument = [[MUTextLogDocument alloc] mockInitWithString: @"Foo: Bar\n\nText"];
  
  [self assert: [logDocument headerForKey: @"Foo"] equals: @"Bar"];
}

- (void) testExtractThreeHeaders
{
  MUTextLogDocument *logDocument = [[MUTextLogDocument alloc] mockInitWithString: @"Foo: Bar\nBaz: Quux\nDate: 01-01-2001\n\nText"];
  
  [self assert: [logDocument headerForKey: @"Foo"] equals: @"Bar"];
  [self assert: [logDocument headerForKey: @"Baz"] equals: @"Quux"];
  [self assert: [logDocument headerForKey: @"Date"] equals: @"01-01-2001"];
}

- (void) testContentAfterHeaders
{
  MUTextLogDocument *logDocument = [[MUTextLogDocument alloc] mockInitWithString: @"Header: Value\nHeader2: Value\n\nBody: text\nIs cool\n"];
  
  [self assert: [logDocument content] equals: @"Body: text\nIs cool\n"];
}

- (void) testHeadersWithoutColon
{
  MUTextLogDocument *logDocument = [[MUTextLogDocument alloc] mockInitWithString: @"Foo\nBar\n\nBaz"];
  
  [self assertNil: logDocument];
}

- (void) testTrimLeadingAndTrailingSpaces
{
  MUTextLogDocument *logDocument = [[MUTextLogDocument alloc] mockInitWithString: @"Header:  Value  \n\nText"];  
  [self assert: [logDocument headerForKey: @"Header"] equals: @"Value"];
}

@end
