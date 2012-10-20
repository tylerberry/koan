//
// MUFugueEditFilterTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFugueEditFilterTests.h"
#import "MUFugueEditFilter.h"

@implementation MUFugueEditFilterTests
{
  NSString *_editString;
}

- (void) setInputViewString: (NSString *) string
{
  _editString = [string copy];
}

- (void) setUp
{
  [super setUp];
  
  _editString = nil;
  
  [self.queue addFilter: [MUFugueEditFilter filterWithDelegate: self]];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testIgnoresNormalInput
{
  [self assertInput: @"Just a normal line of text.\n" hasOutput: @"Just a normal line of text.\n"];
  [self assertNil: _editString]; 
}

- (void) testElidesFugueEdit
{
  [self assertInput: @"FugueEdit > &test me=Test\n" hasOutput: @""];
  [self assert: _editString equals: @"&test me=Test"];
}

@end
