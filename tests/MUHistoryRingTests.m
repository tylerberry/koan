//
// MUHistoryRingTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUHistoryRingTests.h"

NSString *First = @"First";
NSString *Second = @"Second";
NSString *Third = @"Third";

@interface MUHistoryRingTests ()

- (void) assertCurrent: (NSString *) expected;
- (void) assertPrevious: (NSString *) expected;
- (void) assertNext: (NSString *) expected;
- (void) saveOne;
- (void) saveTwo;
- (void) saveThree;

@end

#pragma mark -

@implementation MUHistoryRingTests

- (void) setUp
{
  ring = [[MUHistoryRing alloc] init];
}

- (void) tearDown
{
  return;
}

- (void) testSinglePrevious
{
  [self saveOne];
  
  [self assertPrevious: First];
}

- (void) testMultiplePrevious
{
  [self saveThree];
  
  [self assertPrevious: Third];
  [self assertPrevious: Second];
  [self assertPrevious: First];
}

- (void) testFullCirclePrevious
{
  [self saveOne];
  
  [self assertPrevious: First];
  [self assertPrevious: @""];
}

- (void) testSingleNext
{
  [self saveOne];
  
  [self assertNext: First];
}

- (void) testMultipleNext
{
  [self saveThree];
  
  [self assertNext: First];
  [self assertNext: Second];
  [self assertNext: Third];
}

- (void) testFullCircleNext
{
  [self saveOne];
  
  [self assertNext: First];
  [self assertNext: @""];
}

- (void) testBothWays
{
  [self saveThree];
  
  [self assertPrevious: Third];
  [self assertPrevious: Second];
  [self assertNext: Third];
  [self assertNext: @""];
  [self assertNext: First];
  [self assertNext: Second];
  [self assertPrevious: First];
  [self assertPrevious: @""];
}

- (void) testCurrentString
{
  [self saveThree];
  
  [self assertNext: First];
  [self assertCurrent: First];
  [self assertNext: Second];
  [self assertCurrent: Second];
  [self assertNext: Third];
  [self assertCurrent: Third];
  [self assertNext: @""];
  [self assertCurrent: @""];
}

- (void) testSimpleUpdate
{
  [self saveThree];
  
  [self assertPrevious: Third];
  [self assertPrevious: Second];
  
  [ring updateString: @"Bar Two"];
  
  [self assertPrevious: First];
  [self assertPrevious: @""];
  [self assertPrevious: Third];
  [self assertPrevious: @"Bar Two"];
}

- (void) testUpdateBuffer
{
  [self saveTwo];
  
  [self assertNext: First];
  [self assertNext: Second];
  [self assertNext: @""];
  
  [ring updateString: @"Temporary"];
  
  [self assertNext: First];
  [self assertNext: Second];
  [self assertNext: @"Temporary"];
  
  [ring saveString: @"Something entirely different"];
  
  [self assertPrevious: @"Something entirely different"];
  [self assertPrevious: Second];
  [self assertPrevious: First];
  [self assertPrevious: @""];
}

- (void) testInternalSave
{
  [self saveThree];
  
  [self assertNext: First];
  [self assertNext: Second];
  
  [ring saveString: @"Bar Two"];
  
  [self assertNext: First];
  [self assertNext: Second];
  [self assertNext: Third];
  [self assertNext: @"Bar Two"];
  [self assertNext: @""];
}

- (void) testUpdateThenSaveBuffer
{
  [self saveThree];
  
  [self assertPrevious: Third];
  [self assertPrevious: Second];
  
  [ring updateString: @"Bar Two"];
  
  [self assertPrevious: First];
  [self assertPrevious: @""];
  [self assertPrevious: Third];
  [self assertPrevious: @"Bar Two"];
  [self assertPrevious: First];
  [self assertPrevious: @""];
  
  [ring saveString: @"New"];
  
  [self assertPrevious: @"New"];
  [self assertPrevious: Third];
  [self assertPrevious: @"Bar Two"];
}

- (void) testUpdateAndSaveUpdatedValue
{
  [self saveThree];
  
  [self assertPrevious: Third];
  [self assertPrevious: Second];
  
  [ring updateString: @"Bar Two"];
  
  [self assertPrevious: First];
  [self assertPrevious: @""];
  [self assertPrevious: Third];
  [self assertPrevious: @"Bar Two"];
  
  [ring saveString: @"Updated Bar"];
  
  [self assertPrevious: @"Updated Bar"];
  [self assertPrevious: Third];
  [self assertPrevious: Second];
}

- (void) testNonduplicationOfPreviousCommand
{
  [self saveOne];
  
  [self assertPrevious: First];
  
  [ring saveString: First];
  
  [self assertPrevious: First];
  [self assertPrevious: @""];
}

- (void) testSearchFindsNothing
{
  [ring saveString: @"Dog"];
  
  XCTAssertNil ([ring searchForwardForStringPrefix: @"Cat"]);
}

- (void) testPerfectMatchFindsNothing
{
  [ring saveString: @"Cat"];
  
  XCTAssertNil ([ring searchForwardForStringPrefix: @"Cat"]);
}

- (void) testSearchForward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testWraparoundSearchForward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testMoveForwardThenSearchForward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  [self assertNext: @"Catastrophic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testMoveBackwardThenSearchForward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  [self assertPrevious: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  
  [self assertPrevious: @"Dog"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testSearchForwardWithInterspersedResets
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Catalogue"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");

  [ring resetSearchCursor];

  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");

  [ring resetSearchCursor];

  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testSearchBackward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testMoveForwardThenSearchBackward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  [self assertNext: @"Catastrophic"];
  
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  
  [self assertNext: @"Dog"];
  
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  
}

- (void) testMoveBackwardThenSearchBackward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  [self assertPrevious: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testSearchBackwardWithInterspersedResets
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Catalogue"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");

  [ring resetSearchCursor];

  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catalogue");

  [ring resetSearchCursor];

  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testSearchForwardAndBackward
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Catalogue"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testSearchHonorsUpdates
{
  [ring saveString: @"Catastrophic"];
  [ring saveString: @"Dog"];
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  
  [self assertNext: @"Catastrophic"];
  [self assertNext: @"Dog"];
  
  [ring updateString: @"Catalogue"];
  
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
}

- (void) testSearchForEmptyString
{
  [ring saveString: @"Pixel"];
  
  XCTAssertNil ([ring searchForwardForStringPrefix: @""]);
  XCTAssertNil ([ring searchBackwardForStringPrefix: @""]);
}

- (void) testNumberOfUniqueMatches
{
  [ring saveString: @"Dog"];
  
  XCTAssertEqual ([ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 0);
  
  [ring saveString: @"Cat"];
  
  XCTAssertEqual ([ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 0);
  
  [ring saveString: @"Catatonic"];
  
  XCTAssertEqual ([ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 1);
  
  [ring saveString: @"Catastrophic"];
  
  XCTAssertEqual ([ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 2);
  
  [ring saveString: @"Catastrophic"];
  
  XCTAssertEqual ([ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 2);
}

#pragma mark - Private methods

- (void) assertCurrent: (NSString *) expected
{
  XCTAssertEqualObjects ([ring currentString], expected);
}

- (void) assertPrevious: (NSString *) expected
{
  XCTAssertEqualObjects ([ring previousString], expected);
}

- (void) assertNext: (NSString *) expected
{
  XCTAssertEqualObjects ([ring nextString], expected);
}

- (void) saveOne
{
  [ring saveString: First];
}

- (void) saveTwo
{
  [self saveOne];
  [ring saveString: Second];
}

- (void) saveThree
{
  [self saveTwo];
  [ring saveString: Third];
}

@end
