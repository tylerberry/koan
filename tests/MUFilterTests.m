//
// MUFilterTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilterTests.h"

@implementation MUUpperCaseFilter

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  return [NSAttributedString attributedStringWithString: attributedString.string.uppercaseString
                                             attributes: [attributedString attributesAtIndex: 0 effectiveRange: 0]];
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return [self filterCompleteLine: attributedString];
}

@end

#pragma mark -

@implementation MUFilterQueueTests

- (void) setUp
{
  return;
}

- (void) tearDown
{
  return;
}

- (void) testFilter
{
  MUFilterQueue *queue = [[MUFilterQueue alloc] init];
  
  NSAttributedString *input = [NSAttributedString attributedStringWithString: @"Foo"];
  NSAttributedString *output = [queue processCompleteLine: input];
  [self assert: output equals: input];
}

- (void) testQueue
{
  MUFilterQueue *queue = [[MUFilterQueue alloc] init];
  
  [queue addFilter: [MUUpperCaseFilter filter]];
  
  NSString *baseString = @"Foo";
  NSString *uppercaseString = baseString.uppercaseString;
  NSAttributedString *input = [NSAttributedString attributedStringWithString: baseString];
  NSAttributedString *output = [queue processCompleteLine: input];
  [self assert: output.string equals: uppercaseString];
}

@end
