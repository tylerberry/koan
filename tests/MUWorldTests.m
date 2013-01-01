//
// MUWorldTests.m
//
// Copyright (c) 2013 3James Software.
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

- (void) testUniqueIdentifierPersistsThroughArchiving
{
  _world.name = @"Test World";
  
  NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject: _world];
  MUWorld *unarchivedWorld = [NSKeyedUnarchiver unarchiveObjectWithData: archivedData];
  
  [self assert: _world.uniqueIdentifier equals: unarchivedWorld.uniqueIdentifier];
}

@end
