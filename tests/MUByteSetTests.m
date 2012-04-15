//
// MUByteSetTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUByteSetTests.h"
#import "MUByteSet.h"

@implementation MUByteSetTests

- (void) testEmptySet
{
  MUByteSet *byteSet = [MUByteSet byteSet];
  for (unsigned i = 0; i <= UINT8_MAX; ++i)
    [self assertFalse: [byteSet containsByte: i] message: [NSString stringWithFormat: @"%d should not have been included",i]];
}

- (void) testAddByte
{
  MUByteSet *byteSet = [MUByteSet byteSet];
  [byteSet addByte: 42];
  [byteSet addByte: 31];
  [self assertTrue: [byteSet containsByte: 42] message: @"Expected to contain 42"];
  [self assertTrue: [byteSet containsByte: 31] message: @"Expected to contain 31"];
}

- (void) testAddBytes
{
  MUByteSet *byteSet = [MUByteSet byteSetWithBytes: 0, 42, 27, -1];
  [byteSet addBytes: 3, 4, 5, -1];
  [self assertTrue: [byteSet containsByte: 0] message: @"Expected to contain 0"];
  [self assertTrue: [byteSet containsByte: 42] message: @"Expected to contain 42"];
  [self assertTrue: [byteSet containsByte: 27] message: @"Expected to contain 27"];
  [self assertTrue: [byteSet containsByte: 3] message: @"Expected to contain 3"];
  [self assertTrue: [byteSet containsByte: 4] message: @"Expected to contain 4"];
  [self assertTrue: [byteSet containsByte: 5] message: @"Expected to contain 5"];
}

- (void) testInverseSet
{
  MUByteSet *byteSet = [MUByteSet byteSetWithBytes: 42, 71, -1];
  MUByteSet *inverse = [byteSet inverseSet];
  for (unsigned i = 0; i <= UINT8_MAX; ++i)
  {
    if ([byteSet containsByte: i])
      [self assertFalse: [inverse containsByte: i] message: [NSString stringWithFormat: @"Inverse should not contain %d", i]];
    else
      [self assertTrue: [inverse containsByte: i] message: [NSString stringWithFormat: @"Inverse should contain %d", i]];
  }
}

- (void) testDataValue
{
  uint8_t bytes[] = {31, 47, 73};
  MUByteSet *byteSet = [MUByteSet byteSetWithBytes: bytes length: 3];
  [self assert: [byteSet dataValue] equals: [NSData dataWithBytes: bytes length: 3]];
}

- (void) testRemoveByte
{
  MUByteSet *bytes = [MUByteSet byteSetWithBytes: 42, 53, -1];
  [bytes removeByte: 42];
  [self assertTrue: [bytes containsByte: 53] message: @"53 was removed"];
  [self assertFalse: [bytes containsByte: 42] message: @"42 was not removed"];
}

@end
