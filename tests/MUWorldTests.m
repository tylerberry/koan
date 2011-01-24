//
// MUWorldTests.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUWorldTests.h"
#import "MUWorld.h"
#import "MUPlayer.h"

@implementation MUWorldTests

- (void) setUp
{
  world = [[MUWorld alloc] init];
  player = [[MUPlayer alloc] init];
}

- (void) tearDown
{
  [player release];
  [world release];
}

- (void) testUniqueIdentifier
{
  world.name = @"Test World";
  [self assert: world.uniqueIdentifier equals: @"world:test.world"];
}

@end
