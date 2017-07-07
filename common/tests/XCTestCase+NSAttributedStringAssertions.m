//
// XCTestCase+NSAttributedStringAssertions.m
//
// Copyright (c) 2013 3James Software.
//

#import "XCTestCase+NSAttributedStringAssertions.h"

@implementation XCTestCase (NSAttributedStringAssertions)

- (void) assertAttributedString: (NSAttributedString *) actualString
                   equalsString: (NSString *) expectedString
                        message: (NSString *) message
{
  XCTAssertEqualObjects (actualString.string, expectedString, @"%@", message);
}

- (void) assertAttributedString: (NSAttributedString *) actualString equalsString: (NSString *) expected
{
  [self assertAttributedString: actualString equalsString: expected message: nil];
}

- (void) assertAttributesTheSameInString: (NSAttributedString *) string
                               withRange: (NSRange) range
                                 message: (NSString *) message
{
  NSRange result;
  
  [string attributesAtIndex: range.location longestEffectiveRange: &result inRange: range];

  XCTAssertEqual (result.length, range.length, @"%@", message);
}

- (void) assertAttributesTheSameInString: (NSAttributedString *) string withRange: (NSRange) range
{
  [self assertAttributesTheSameInString: string withRange: range message: nil];
}

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString *) string
                 atIndex: (NSUInteger) characterIndex
                 message: (NSString *) message
{
  NSDictionary *attributes = [string attributesAtIndex: characterIndex effectiveRange: NULL];

  XCTAssertEqualObjects (attributes[attributeName], expectedValue, @"%@", message);
}

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString *) string
                 atIndex: (NSUInteger) characterIndex
{
  [self assertAttribute: attributeName
                 equals: expectedValue
     inAttributedString: string
                atIndex: characterIndex
                message: nil];
}

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString*) string
               withRange: (NSRange) range
                 message: (NSString *) message
{
  [self assertAttribute: attributeName
                 equals: expectedValue
     inAttributedString: string
                atIndex: range.location];

  [self assertAttributesTheSameInString: string withRange: range message: message];
}

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString *) string
               withRange: (NSRange) range
{
  [self assertAttribute: attributeName equals: expectedValue inAttributedString: string withRange: range message: nil];
}

@end
