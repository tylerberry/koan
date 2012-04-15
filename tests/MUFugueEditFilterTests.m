//
// MUFugueEditFilterTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFugueEditFilterTests.h"
#import "MUFugueEditFilter.h"

@implementation MUFugueEditFilterTests

- (void) setInputViewString: (NSString *) string
{
  editString = [string copy];
}

- (void) setUp
{
  editString = nil;
  queue = [[MUFilterQueue alloc] init];
  [queue addFilter: [MUFugueEditFilter filterWithDelegate: self]];
}

- (void) tearDown
{
}

- (void) testIgnoresNormalInput
{
  [self assertInput: @"Just a normal line of text.\n" hasOutput: @"Just a normal line of text.\n"];
  [self assertNil: editString]; 
}

- (void) testElidesFugueEdit
{
  [self assertInput: @"FugueEdit > &test me=Test\n" hasOutput: @""];
  [self assert: editString equals: @"&test me=Test"];
}

@end
