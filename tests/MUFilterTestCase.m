//
// MUFilterTestCase.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFilterTestCase.h"

@implementation MUFilterTestCase

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output
{
  [self assertInput: input hasOutput: output message: nil];
}

- (void) assertInput: (NSString *) input hasOutput: (NSString *) output message: (NSString *) message
{
  NSAttributedString *attributedInput = [self constructAttributedStringForString: input];
  NSAttributedString *attributedExpectedOutput = [NSAttributedString attributedStringWithString: output];
  NSMutableAttributedString *actualOutput = [NSMutableAttributedString attributedStringWithAttributedString: [queue processAttributedString: attributedInput]];
  
  [actualOutput setAttributes: [NSDictionary dictionary] range: NSMakeRange (0, actualOutput.length)];
  [self assert: actualOutput equals: attributedExpectedOutput message: message];  
}

- (NSMutableAttributedString *) constructAttributedStringForString: (NSString *) string
{
  NSFont *font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  
  [attributes setValue: font forKey: NSFontAttributeName];
  return [NSMutableAttributedString attributedStringWithString: string attributes: attributes];
}

@end
