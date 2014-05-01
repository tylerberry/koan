//
// MUByteSetTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUByteSetTests.h"
#import "MUByteSet.h"

@implementation MUByteSetTests

- (void) setUp
{
  return;
}

- (void) tearDown
{
  return;
}

- (void) testEmptySet
{
  MUByteSet *byteSet = [MUByteSet byteSet];

  for (uint16_t i = 0; i <= UINT8_MAX; ++i)
  {
    XCTAssertFalse ([byteSet containsByte: (uint8_t) i], @"%d should not have been included", i);
  }
}

- (void) testAddByte
{
  MUByteSet *byteSet = [MUByteSet byteSet];
  [byteSet addByte: 42];
  [byteSet addByte: 31];

  XCTAssertTrue ([byteSet containsByte: 42], @"Expected to contain 42");
  XCTAssertTrue ([byteSet containsByte: 31], @"Expected to contain 31");
}

- (void) testAddBytes
{
  MUByteSet *byteSet = [MUByteSet byteSetWithBytes: 0, 42, 27, -1];
  [byteSet addBytes: 3, 4, 5, -1];

  XCTAssertTrue ([byteSet containsByte: 0], @"Expected to contain 0");
  XCTAssertTrue ([byteSet containsByte: 42], @"Expected to contain 42");
  XCTAssertTrue ([byteSet containsByte: 27], @"Expected to contain 27");
  XCTAssertTrue ([byteSet containsByte: 3], @"Expected to contain 3");
  XCTAssertTrue ([byteSet containsByte: 4], @"Expected to contain 4");
  XCTAssertTrue ([byteSet containsByte: 5], @"Expected to contain 5");
}

- (void) testInverseSet
{
  MUByteSet *byteSet = [MUByteSet byteSetWithBytes: 42, 71, -1];
  MUByteSet *inverse = byteSet.inverseSet;
  for (uint16_t i = 0; i <= UINT8_MAX; ++i)
  {
    if ([byteSet containsByte: (uint8_t) i])
    {
      XCTAssertFalse ([inverse containsByte: (uint8_t) i], @"Inverse should not contain %u", i);
    }
    else
    {
      XCTAssertTrue ([inverse containsByte: (uint8_t) i], @"Inverse should contain %u", i);
    }
  }
}

- (void) testDataValue
{
  uint8_t bytes[] = {31, 47, 73};
  MUByteSet *byteSet = [MUByteSet byteSetWithBytes: bytes length: 3];
  XCTAssertEqualObjects (byteSet.dataValue, [NSData dataWithBytes: bytes length: 3]);
}

- (void) testRemoveByte
{
  MUByteSet *bytes = [MUByteSet byteSetWithBytes: 42, 53, -1];
  [bytes removeByte: 42];
  XCTAssertTrue ([bytes containsByte: 53], @"53 was removed");
  XCTAssertFalse ([bytes containsByte: 42], @"42 was not removed");
}

@end
