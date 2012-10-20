//
// MUWorldTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorldTests.h"
#import "MUWorld.h"
#import "MUPlayer.h"

@implementation MUWorldTests
{
  MUWorld *_world;
  MUPlayer *_player;
}

- (void) setUp
{
  _world = [[MUWorld alloc] init];
  _player = [[MUPlayer alloc] init];
}

- (void) tearDown
{
  _world = nil;
  _player = nil;
}

- (void) testUniqueIdentifier
{
  _world.name = @"Test World";
  [self assert: _world.uniqueIdentifier equals: @"world:test.world"];
}

@end
