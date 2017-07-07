//
// MUFilterTestCase.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilterTestCase.h"

@implementation MUFilterTestCase

- (void) setUp
{
  [super setUp];
  self.queue = [MUFilterQueue filterQueue];
}

- (void) tearDown
{
  self.queue = nil;
  [super tearDown];
}

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output
{
  [self assertInput: input hasOutput: output message: nil];
}

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output message: (NSString *) message
{
  NSAttributedString *attributedInput = [self constructAttributedStringForString: input];
  NSAttributedString *actualOutput = [self.queue processCompleteLine: attributedInput];

  XCTAssertEqualObjects (actualOutput.string, output, @"%@", message);
}

- (NSMutableAttributedString *) constructAttributedStringForString: (NSString *) string
{
  NSFont *font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  
  [attributes setValue: font forKey: NSFontAttributeName];
  return [[NSMutableAttributedString alloc] initWithString: string attributes: attributes];
}

@end
