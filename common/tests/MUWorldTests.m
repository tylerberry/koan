//
// MUWorldTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"
#import "MUPlayer.h"

@interface MUWorldTests : XCTestCase

@end

#pragma mark -

@implementation MUWorldTests
{
  MUWorld *_world;
  MUPlayer *_player;
}

- (void) setUp
{
  [super setUp];
  _world = [[MUWorld alloc] init];
  _player = [[MUPlayer alloc] init];
}

- (void) tearDown
{
  _world = nil;
  _player = nil;
  [super tearDown];
}

- (void) testUniqueIdentifierPersistsThroughArchiving
{
  _world.name = @"Test World";
  
  NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject: _world];
  MUWorld *unarchivedWorld = [NSKeyedUnarchiver unarchiveObjectWithData: archivedData];
  
  XCTAssertEqualObjects (_world.uniqueIdentifier, unarchivedWorld.uniqueIdentifier);
}

@end
