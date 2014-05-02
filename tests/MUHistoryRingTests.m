//
// MUHistoryRingTests.m
//
// Copyright (c) 2013 3James Software.
//

#define FIRST @"Peter Wiggin"
#define SECOND @"Valentine Wiggin"
#define THIRD @"Andrew Wiggin"

#import "MUHistoryRing.h"

@interface MUHistoryRingTests : XCTestCase

- (void) _assertCurrent: (NSString *) expected;
- (void) _assertPrevious: (NSString *) expected;
- (void) _assertNext: (NSString *) expected;
- (void) _saveOne;
- (void) _saveTwo;
- (void) _saveThree;

@end

#pragma mark -

@implementation MUHistoryRingTests
{
  MUHistoryRing *_ring;
}

- (void) setUp
{
  [super setUp];
  _ring = [[MUHistoryRing alloc] init];
}

- (void) tearDown
{
  _ring = nil;
  [super tearDown];
}

- (void) testSinglePrevious
{
  [self _saveOne];
  
  [self _assertPrevious: FIRST];
}

- (void) testMultiplePrevious
{
  [self _saveThree];
  
  [self _assertPrevious: THIRD];
  [self _assertPrevious: SECOND];
  [self _assertPrevious: FIRST];
}

- (void) testFullCirclePrevious
{
  [self _saveOne];
  
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
}

- (void) testSingleNext
{
  [self _saveOne];
  
  [self _assertNext: FIRST];
}

- (void) testMultipleNext
{
  [self _saveThree];
  
  [self _assertNext: FIRST];
  [self _assertNext: SECOND];
  [self _assertNext: THIRD];
}

- (void) testFullCircleNext
{
  [self _saveOne];
  
  [self _assertNext: FIRST];
  [self _assertNext: @""];
}

- (void) testBothWays
{
  [self _saveThree];
  
  [self _assertPrevious: THIRD];
  [self _assertPrevious: SECOND];
  [self _assertNext: THIRD];
  [self _assertNext: @""];
  [self _assertNext: FIRST];
  [self _assertNext: SECOND];
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
}

- (void) testCurrentString
{
  [self _saveThree];
  
  [self _assertNext: FIRST];
  [self _assertCurrent: FIRST];
  [self _assertNext: SECOND];
  [self _assertCurrent: SECOND];
  [self _assertNext: THIRD];
  [self _assertCurrent: THIRD];
  [self _assertNext: @""];
  [self _assertCurrent: @""];
}

- (void) testSimpleUpdate
{
  [self _saveThree];
  
  [self _assertPrevious: THIRD];
  [self _assertPrevious: SECOND];
  
  [_ring updateString: @"Bar Two"];
  
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
  [self _assertPrevious: THIRD];
  [self _assertPrevious: @"Bar Two"];
}

- (void) testUpdateBuffer
{
  [self _saveTwo];
  
  [self _assertNext: FIRST];
  [self _assertNext: SECOND];
  [self _assertNext: @""];
  
  [_ring updateString: @"Temporary"];
  
  [self _assertNext: FIRST];
  [self _assertNext: SECOND];
  [self _assertNext: @"Temporary"];
  
  [_ring saveString: @"Something entirely different"];
  
  [self _assertPrevious: @"Something entirely different"];
  [self _assertPrevious: SECOND];
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
}

- (void) testInternalSave
{
  [self _saveThree];
  
  [self _assertNext: FIRST];
  [self _assertNext: SECOND];
  
  [_ring saveString: @"Bar Two"];
  
  [self _assertNext: FIRST];
  [self _assertNext: SECOND];
  [self _assertNext: THIRD];
  [self _assertNext: @"Bar Two"];
  [self _assertNext: @""];
}

- (void) testUpdateThenSaveBuffer
{
  [self _saveThree];
  
  [self _assertPrevious: THIRD];
  [self _assertPrevious: SECOND];
  
  [_ring updateString: @"Bar Two"];
  
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
  [self _assertPrevious: THIRD];
  [self _assertPrevious: @"Bar Two"];
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
  
  [_ring saveString: @"New"];
  
  [self _assertPrevious: @"New"];
  [self _assertPrevious: THIRD];
  [self _assertPrevious: @"Bar Two"];
}

- (void) testUpdateAndSaveUpdatedValue
{
  [self _saveThree];
  
  [self _assertPrevious: THIRD];
  [self _assertPrevious: SECOND];
  
  [_ring updateString: @"Bar Two"];
  
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
  [self _assertPrevious: THIRD];
  [self _assertPrevious: @"Bar Two"];
  
  [_ring saveString: @"Updated Bar"];
  
  [self _assertPrevious: @"Updated Bar"];
  [self _assertPrevious: THIRD];
  [self _assertPrevious: SECOND];
}

- (void) testNonduplicationOfPreviousCommand
{
  [self _saveOne];
  
  [self _assertPrevious: FIRST];
  
  [_ring saveString: FIRST];
  
  [self _assertPrevious: FIRST];
  [self _assertPrevious: @""];
}

- (void) testSearchFindsNothing
{
  [_ring saveString: @"Dog"];
  
  XCTAssertNil ([_ring searchForwardForStringPrefix: @"Cat"]);
}

- (void) testPerfectMatchFindsNothing
{
  [_ring saveString: @"Cat"];
  
  XCTAssertNil ([_ring searchForwardForStringPrefix: @"Cat"]);
}

- (void) testSearchForward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testWraparoundSearchForward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testMoveForwardThenSearchForward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  [self _assertNext: @"Catastrophic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testMoveBackwardThenSearchForward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  [self _assertPrevious: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  
  [self _assertPrevious: @"Dog"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testSearchForwardWithInterspersedResets
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Catalogue"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");

  [_ring resetSearchCursor];

  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");

  [_ring resetSearchCursor];

  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testSearchBackward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testMoveForwardThenSearchBackward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  [self _assertNext: @"Catastrophic"];
  
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  
  [self _assertNext: @"Dog"];
  
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  
}

- (void) testMoveBackwardThenSearchBackward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  [self _assertPrevious: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testSearchBackwardWithInterspersedResets
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Catalogue"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");

  [_ring resetSearchCursor];

  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catalogue");

  [_ring resetSearchCursor];

  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
}

- (void) testSearchForwardAndBackward
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Catalogue"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([_ring searchBackwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
}

- (void) testSearchHonorsUpdates
{
  [_ring saveString: @"Catastrophic"];
  [_ring saveString: @"Dog"];
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  
  [self _assertNext: @"Catastrophic"];
  [self _assertNext: @"Dog"];
  
  [_ring updateString: @"Catalogue"];
  
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catatonic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catastrophic");
  XCTAssertEqualObjects ([_ring searchForwardForStringPrefix: @"Cat"], @"Catalogue");
}

- (void) testSearchForEmptyString
{
  [_ring saveString: @"Pixel"];
  
  XCTAssertNil ([_ring searchForwardForStringPrefix: @""]);
  XCTAssertNil ([_ring searchBackwardForStringPrefix: @""]);
}

- (void) testNumberOfUniqueMatches
{
  [_ring saveString: @"Dog"];
  
  XCTAssertEqual ([_ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 0);
  
  [_ring saveString: @"Cat"];
  
  XCTAssertEqual ([_ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 0);
  
  [_ring saveString: @"Catatonic"];
  
  XCTAssertEqual ([_ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 1);
  
  [_ring saveString: @"Catastrophic"];
  
  XCTAssertEqual ([_ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 2);
  
  [_ring saveString: @"Catastrophic"];
  
  XCTAssertEqual ([_ring numberOfUniqueMatchesForStringPrefix: @"Cat"], (NSUInteger) 2);
}

#pragma mark - Private methods

- (void) _assertCurrent: (NSString *) expected
{
  XCTAssertEqualObjects ([_ring currentString], expected);
}

- (void) _assertPrevious: (NSString *) expected
{
  XCTAssertEqualObjects ([_ring previousString], expected);
}

- (void) _assertNext: (NSString *) expected
{
  XCTAssertEqualObjects ([_ring nextString], expected);
}

- (void) _saveOne
{
  [_ring saveString: FIRST];
}

- (void) _saveTwo
{
  [self _saveOne];
  [_ring saveString: SECOND];
}

- (void) _saveThree
{
  [self _saveTwo];
  [_ring saveString: THIRD];
}

@end
