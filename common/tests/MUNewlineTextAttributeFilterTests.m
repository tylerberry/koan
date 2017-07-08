//
// MUNewlineTextAttributeFilterTests.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUFilterTestCase.h"
#import "MUNewlineTextAttributeFilter.h"
#import "MUConstants.h"

@interface MUNewlineTextAttributeFilterTests : MUFilterTestCase

@end

#pragma mark -

@implementation MUNewlineTextAttributeFilterTests

- (void) setUp
{
  [super setUp];
  [self.queue addFilter: [MUNewlineTextAttributeFilter filter]];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testSingleNewline
{
  NSDictionary *attributes = @{MUInverseColorsAttributeName: @YES,
                               MUCustomBackgroundColorAttributeName: @(MUColorTagANSIRed),
                               NSBackgroundColorAttributeName: [NSColor redColor],
                               NSFontAttributeName: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]};
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: @"a\nb" attributes: attributes];

  NSAttributedString *results = [self.queue processCompleteLine: attributedString];

  XCTAssertNotNil ([results attribute: MUInverseColorsAttributeName atIndex: 0 effectiveRange: NULL]);
  XCTAssertNil ([results attribute: MUInverseColorsAttributeName atIndex: 1 effectiveRange: NULL]);
  XCTAssertNotNil ([results attribute: MUInverseColorsAttributeName atIndex: 2 effectiveRange: NULL]);

  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 0 effectiveRange: NULL],
                         @(MUColorTagANSIRed));
  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 1 effectiveRange: NULL],
                         @(MUColorTagDefaultBackground));
  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 2 effectiveRange: NULL],
                         @(MUColorTagANSIRed));

  XCTAssertEqualObjects ([results attribute: NSBackgroundColorAttributeName atIndex: 0 effectiveRange: NULL],
                         [NSColor redColor]);
  XCTAssertNil ([results attribute: NSBackgroundColorAttributeName atIndex: 1 effectiveRange: NULL]);
  XCTAssertEqualObjects ([results attribute: NSBackgroundColorAttributeName atIndex: 2 effectiveRange: NULL],
                         [NSColor redColor]);

  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 0 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 1 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 2 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
}

- (void) testMultipleNewlines
{
  NSDictionary *attributes = @{MUInverseColorsAttributeName: @YES,
                               MUCustomBackgroundColorAttributeName: @(MUColorTagANSIRed),
                               NSBackgroundColorAttributeName: [NSColor redColor],
                               NSFontAttributeName: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]};
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: @"a\nb\nc" attributes: attributes];

  NSAttributedString *results = [self.queue processCompleteLine: attributedString];

  XCTAssertNotNil ([results attribute: MUInverseColorsAttributeName atIndex: 0 effectiveRange: NULL]);
  XCTAssertNil ([results attribute: MUInverseColorsAttributeName atIndex: 1 effectiveRange: NULL]);
  XCTAssertNotNil ([results attribute: MUInverseColorsAttributeName atIndex: 2 effectiveRange: NULL]);
  XCTAssertNil ([results attribute: MUInverseColorsAttributeName atIndex: 3 effectiveRange: NULL]);
  XCTAssertNotNil ([results attribute: MUInverseColorsAttributeName atIndex: 4 effectiveRange: NULL]);

  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 0 effectiveRange: NULL],
                         @(MUColorTagANSIRed));
  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 1 effectiveRange: NULL],
                         @(MUColorTagDefaultBackground));
  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 2 effectiveRange: NULL],
                         @(MUColorTagANSIRed));
  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 3 effectiveRange: NULL],
                         @(MUColorTagDefaultBackground));
  XCTAssertEqualObjects ([results attribute: MUCustomBackgroundColorAttributeName atIndex: 4 effectiveRange: NULL],
                         @(MUColorTagANSIRed));

  XCTAssertEqualObjects ([results attribute: NSBackgroundColorAttributeName atIndex: 0 effectiveRange: NULL],
                         [NSColor redColor]);
  XCTAssertNil ([results attribute: NSBackgroundColorAttributeName atIndex: 1 effectiveRange: NULL]);
  XCTAssertEqualObjects ([results attribute: NSBackgroundColorAttributeName atIndex: 2 effectiveRange: NULL],
                         [NSColor redColor]);
  XCTAssertNil ([results attribute: NSBackgroundColorAttributeName atIndex: 3 effectiveRange: NULL]);
  XCTAssertEqualObjects ([results attribute: NSBackgroundColorAttributeName atIndex: 4 effectiveRange: NULL],
                         [NSColor redColor]);

  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 0 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 1 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 2 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 3 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
  XCTAssertEqualObjects ([results attribute: NSFontAttributeName atIndex: 4 effectiveRange: NULL],
                         [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]);
}

@end
