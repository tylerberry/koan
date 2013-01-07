//
// J3TestCase (NSAttributedStringAssertions).h
//
// Copyright (c) 2013 3James Software.
//

#import "J3TestCase.h"

@interface J3TestCase (NSAttributedStringAssertions)

- (void) assertAttributedString: (NSAttributedString *) actualString
                   equalsString: (NSString *) expectedString
                        message: (NSString *) message;

- (void) assertAttributedString: (NSAttributedString *) actualString
                   equalsString: (NSString *) expectedString;

- (void) assertAttributesTheSameInString: (NSAttributedString *) string
                               withRange: (NSRange)range
                                 message: (NSString *) message;

- (void) assertAttributesTheSameInString: (NSAttributedString *) string
                               withRange: (NSRange)range;

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString *) string
                 atIndex: (NSUInteger) index
                 message: (NSString *) message;

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString *) string
                 atIndex: (NSUInteger) index;

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString*) string
               withRange: (NSRange)range
                 message: (NSString *) message;

- (void) assertAttribute: (NSString *) attributeName
                  equals: (id) expectedValue
      inAttributedString: (NSAttributedString*) string
               withRange: (NSRange)range;

@end
