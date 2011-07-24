//
// MUNaiveURLFilterTests.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUNaiveURLFilterTests.h"
#import "MUNaiveURLFilter.h"
#import "categories/NSURL (Allocating).h"

@interface MUNaiveURLFilterTests (Private)

- (void) assertInput: (NSString *) input producesURL: (NSURL *) url forRange: (NSRange) range;

@end

#pragma mark -

@implementation MUNaiveURLFilterTests (Private)

- (void) assertInput: (NSString *) input producesURL: (NSURL *) url forRange: (NSRange) range
{
  NSAttributedString *attributedInput =
  [NSAttributedString attributedStringWithString: input];
  NSAttributedString *attributedOutput =
    [queue processAttributedString: attributedInput];
  NSURL *foundURL;
  NSRange foundRange;
  
  [self assert: [attributedInput string]
        equals: [attributedOutput string]
       message: @"Strings not equal."];  
  
  if (range.location != 0)
  {
    foundURL = [attributedOutput attribute: NSLinkAttributeName
                                   atIndex: range.location - 1
                     longestEffectiveRange: &foundRange
                                   inRange: NSMakeRange (0, [input length])];
    
    [self assertFalse: [foundURL isEqual: url]
              message: @"Preceding character matches url and shouldn't."];
  }
  
  if (NSMaxRange (range) < [input length])
  {
    foundURL = [attributedOutput attribute: NSLinkAttributeName
                                   atIndex: NSMaxRange (range)
                     longestEffectiveRange: &foundRange
                                   inRange: NSMakeRange (0, [input length])];
    
    [self assertFalse: [foundURL isEqual: url]
              message: @"Following character matches url and shouldn't."];
  }
  
  foundURL = [attributedOutput attribute: NSLinkAttributeName
                                  atIndex: range.location
                    longestEffectiveRange: &foundRange
                                  inRange: NSMakeRange (0, [input length])];
  
  [self assert: foundURL
        equals: url
       message: @"Links don't match."];
  
  if (foundURL)
  {
    [self assert: [NSNumber numberWithUnsignedInt: foundRange.location]
          equals: [NSNumber numberWithUnsignedInt: range.location]
         message: @"Range locations don't match."];
    
    [self assert: [NSNumber numberWithUnsignedInt: foundRange.length]
          equals: [NSNumber numberWithUnsignedInt: range.length]
         message: @"Range lengths don't match."];
  }
}

@end

#pragma mark -

@implementation MUNaiveURLFilterTests

- (void) setUp
{
  queue = [[MUFilterQueue alloc] init];
  [queue addFilter: [MUNaiveURLFilter filter]];
}

- (void) tearDown
{
  [queue release];
}

- (void) testNoLink
{
  [self assertInput: @"nonsense"
        producesURL: nil
           forRange: NSMakeRange (0, [@"nonsense" length])];
}

- (void) testCanonicalLink
{
  NSString *input = @"http://www.google.com/";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.google.com/"]
           forRange: [input rangeOfString: @"http://www.google.com/"]];
}

- (void) testSlashlessLink
{
  NSString *input = @"http://www.google.com";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.google.com"]
           forRange: [input rangeOfString: @"http://www.google.com"]];
}

- (void) testInformalLink
{
  NSString *input = @"www.google.com";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.google.com"]
           forRange: [input rangeOfString: @"www.google.com"]];
}

- (void) testLinkAtStart
{
  NSString *input = @"www.3james.com is the link";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.3james.com"]
           forRange: [input rangeOfString: @"www.3james.com"]];
}

- (void) testLinkAtEnd
{
  NSString *input = @"The link is www.3james.com";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.3james.com"]
           forRange: [input rangeOfString: @"www.3james.com"]];
}

- (void) testLinkInMiddle
{
  NSString *input = @"I heard that www.3james.com is the link";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.3james.com"]
           forRange: [input rangeOfString: @"www.3james.com"]];
}

- (void) testLinkInSeparators
{
  NSString *input = @" <www.google.com> ";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.google.com"]
           forRange: [input rangeOfString: @"www.google.com"]];
}

- (void) testLinkFollowedByPunctuation
{
  NSString *input = @"Is the link www.google.com?";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"http://www.google.com"]
           forRange: [input rangeOfString: @"www.google.com"]];
}

- (void) testCanonicalEmail
{
  NSString *input = @"mailto:test@example.com";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"mailto:test@example.com"]
           forRange: [input rangeOfString: @"mailto:test@example.com"]];
}

- (void) testInformalEmail
{
  NSString *input = @"test@example.com";
  
  [self assertInput: input
        producesURL: [NSURL URLWithString: @"mailto:test@example.com"]
           forRange: [input rangeOfString: @"test@example.com"]];
}

@end
