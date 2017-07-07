//
// MUAutoHyperlinksFilterTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAutoHyperlinksFilter.h"
#import "MUFilterQueue.h"

@interface MUAutoHyperlinksFilterTests : XCTestCase

- (void) _assertInput: (NSString *) input producesURL: (NSURL *) url forRange: (NSRange) range;

@end

#pragma mark -

@implementation MUAutoHyperlinksFilterTests
{
  MUFilterQueue *_queue;
}

- (void) setUp
{
  [super setUp];
  _queue = [[MUFilterQueue alloc] init];
  [_queue addFilter: [MUAutoHyperlinksFilter filter]];
}

- (void) tearDown
{
  _queue = nil;
  [super tearDown];
}

- (void) testNoLink
{
  [self _assertInput: @"nonsense"
         producesURL: nil
            forRange: NSMakeRange (0, [@"nonsense" length])];
}

- (void) testCanonicalLink
{
  NSString *input = @"http://www.google.com/";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.google.com/"]
            forRange: [input rangeOfString: @"http://www.google.com/"]];
}

- (void) testSlashlessLink
{
  NSString *input = @"http://www.google.com";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.google.com"]
            forRange: [input rangeOfString: @"http://www.google.com"]];
}

- (void) testInformalLink
{
  NSString *input = @"www.google.com";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.google.com"]
            forRange: [input rangeOfString: @"www.google.com"]];
}

- (void) testLinkAtStart
{
  NSString *input = @"www.3james.com is the link";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.3james.com"]
            forRange: [input rangeOfString: @"www.3james.com"]];
}

- (void) testLinkAtEnd
{
  NSString *input = @"The link is www.3james.com";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.3james.com"]
            forRange: [input rangeOfString: @"www.3james.com"]];
}

- (void) testLinkInMiddle
{
  NSString *input = @"I heard that www.3james.com is the link";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.3james.com"]
            forRange: [input rangeOfString: @"www.3james.com"]];
}

- (void) testLinkInSeparators
{
  NSString *input = @" <www.google.com> ";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.google.com"]
            forRange: [input rangeOfString: @"www.google.com"]];
}

- (void) testLinkFollowedByPunctuation
{
  NSString *input = @"Is the link www.google.com?";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"http://www.google.com"]
            forRange: [input rangeOfString: @"www.google.com"]];
}

- (void) testCanonicalEmail
{
  NSString *input = @"mailto:test@example.com";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"mailto:test@example.com"]
            forRange: [input rangeOfString: @"mailto:test@example.com"]];
}

- (void) testInformalEmail
{
  NSString *input = @"test@example.com";

  [self _assertInput: input
         producesURL: [NSURL URLWithString: @"mailto:test@example.com"]
            forRange: [input rangeOfString: @"test@example.com"]];
}

#pragma mark - Private methods

- (void) _assertInput: (NSString *) input producesURL: (NSURL *) url forRange: (NSRange) range
{
  NSAttributedString *attributedInput = [[NSAttributedString alloc] initWithString: input];
  NSAttributedString *attributedOutput = [_queue processCompleteLine: attributedInput];
  NSURL *foundURL;
  NSRange foundRange;

  XCTAssertEqualObjects (attributedInput.string, attributedOutput.string, @"Strings not equal.");

  if (range.location != 0)
  {
    foundURL = [attributedOutput attribute: NSLinkAttributeName
                                   atIndex: range.location - 1
                     longestEffectiveRange: &foundRange
                                   inRange: NSMakeRange (0, input.length)];

    XCTAssertNotEqualObjects (foundURL, url, @"Preceding character matches url and shouldn't.");
  }

  if (NSMaxRange (range) < [input length])
  {
    foundURL = [attributedOutput attribute: NSLinkAttributeName
                                   atIndex: NSMaxRange (range)
                     longestEffectiveRange: &foundRange
                                   inRange: NSMakeRange (0, input.length)];

    XCTAssertNotEqualObjects (foundURL, url, @"Following character matches url and shouldn't.");
  }

  foundURL = [attributedOutput attribute: NSLinkAttributeName
                                 atIndex: range.location
                   longestEffectiveRange: &foundRange
                                 inRange: NSMakeRange (0, input.length)];

  XCTAssertEqualObjects (foundURL, url, @"Links don't match.");

  if (foundURL)
  {
    XCTAssertEqual (foundRange.location, range.location, @"Range locations don't match.");
    XCTAssertEqual (foundRange.length, range.length, @"Range lengths don't match.");
  }
}

@end
