//
// J3FilterTests.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3FilterTests.h"

@implementation J3UpperCaseFilter

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  return [NSAttributedString attributedStringWithString: [[string string] uppercaseString]
                                             attributes: [string attributesAtIndex: 0 effectiveRange: 0]];
}

@end

#pragma mark -

@implementation J3FilterQueueTests

- (void) testFilter
{
  J3FilterQueue *queue = [[J3FilterQueue alloc] init];
  
  NSAttributedString *input = [NSAttributedString attributedStringWithString: @"Foo"];
  NSAttributedString *output = [queue processAttributedString: input];
  [self assert: output equals: input];
  [queue release];
}

- (void) testQueue
{
  J3FilterQueue *queue = [[J3FilterQueue alloc] init];
  
  [queue addFilter: [J3UpperCaseFilter filter]];
  
  NSString *baseString = @"Foo";
  NSString *uppercaseString = [baseString uppercaseString];
  NSAttributedString *input = [NSAttributedString attributedStringWithString: baseString];
  NSAttributedString *output = [queue processAttributedString: input];
  [self assert: [output string] equals: uppercaseString];
  [queue release];
}

@end
