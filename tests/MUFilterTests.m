//
// MUFilterTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFilterTests.h"

@implementation MUUpperCaseFilter

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  return [NSAttributedString attributedStringWithString: [[string string] uppercaseString]
                                             attributes: [string attributesAtIndex: 0 effectiveRange: 0]];
}

@end

#pragma mark -

@implementation MUFilterQueueTests

- (void) testFilter
{
  MUFilterQueue *queue = [[MUFilterQueue alloc] init];
  
  NSAttributedString *input = [NSAttributedString attributedStringWithString: @"Foo"];
  NSAttributedString *output = [queue processAttributedString: input];
  [self assert: output equals: input];
}

- (void) testQueue
{
  MUFilterQueue *queue = [[MUFilterQueue alloc] init];
  
  [queue addFilter: [MUUpperCaseFilter filter]];
  
  NSString *baseString = @"Foo";
  NSString *uppercaseString = [baseString uppercaseString];
  NSAttributedString *input = [NSAttributedString attributedStringWithString: baseString];
  NSAttributedString *output = [queue processAttributedString: input];
  [self assert: [output string] equals: uppercaseString];
}

@end
