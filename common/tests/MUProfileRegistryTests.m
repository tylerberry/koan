//
// MUProfileRegistryTest.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfileRegistry.h"
#import "MUProfile.h"
#import "MUWorld.h"

@interface MUProfileRegistryTests : XCTestCase

- (void) _assertProfile: (MUProfile *) profile world: (MUWorld *) world player: (MUPlayer *) player;

- (MUWorld *) _createTestWorld;
- (MUPlayer *) _createTestPlayerWithParentWorld: (MUWorld *) world;

@end

#pragma mark -

@implementation MUProfileRegistryTests
{
  MUProfileRegistry *_registry;
}

- (void) setUp
{
  [super setUp];
  _registry = [[MUProfileRegistry alloc] init];
}

- (void) tearDown
{
  _registry = nil;
  [super tearDown];
}

- (void) testSharedRegistry
{
  MUProfileRegistry *registryOne, *registryTwo;
  
  registryOne = [MUProfileRegistry defaultRegistry];
  XCTAssertNotNil (registryOne);
  
  registryTwo = [MUProfileRegistry defaultRegistry];
  XCTAssertNotNil (registryTwo);
  XCTAssertEqualObjects (registryOne, registryTwo);
}

- (void) testProfileWithWorld
{
  MUProfile *profileOne = nil;
  MUProfile *profileTwo = nil;
  MUWorld *world = [self _createTestWorld];
  
  profileOne = [_registry profileForWorld: world];
  [self _assertProfile: profileOne world: world player: nil];
  
  profileTwo = [_registry profileForUniqueIdentifier: world.uniqueIdentifier];
  XCTAssertEqualObjects (profileTwo, profileOne, @"First");
  
  profileOne = [_registry profileForWorld: world];
  XCTAssertEqualObjects (profileOne, profileTwo, @"Second");

  [_registry removeAllProfilesForWorld: world];
}

- (void) testProfileWithWorldAndPlayer
{
  MUProfile *profileOne = nil, *profileTwo = nil;
  MUWorld *world = [self _createTestWorld];
  MUPlayer *player = [self _createTestPlayerWithParentWorld: world];
  
  profileOne = [_registry profileForWorld: world player: player];
  [self _assertProfile: profileOne world: world player: player];
  
  profileTwo = [_registry profileForUniqueIdentifier: player.uniqueIdentifier];
  XCTAssertEqualObjects (profileTwo, profileOne, @"First");
  
  profileOne = [_registry profileForWorld: world player: player];
  XCTAssertEqualObjects (profileOne, profileTwo, @"Second");

  [_registry removeProfileForUniqueIdentifier: player.uniqueIdentifier];
}

- (void) testContains
{
  MUWorld *world = [self _createTestWorld];
  MUPlayer *player = [self _createTestPlayerWithParentWorld: world];
  
  XCTAssertFalse ([_registry containsProfileForWorld: world player: player], @"Before adding");
  
  [_registry profileForWorld: world player: player];
  
  XCTAssertTrue ([_registry containsProfileForWorld: world player: player], @"After adding");

  [_registry removeProfileForWorld: world player: player];
}

- (void) testRemove
{
  MUWorld *world = [self _createTestWorld];
  MUPlayer *player = [self _createTestPlayerWithParentWorld: world];

  [_registry profileForWorld: world player: player];
  XCTAssertTrue ([_registry containsProfileForWorld: world player: player], @"Before removing");
  
  [_registry removeProfileForWorld: world player: player];  
  XCTAssertFalse ([_registry containsProfileForWorld: world player: player], @"After removing");
}

- (void) testRemoveWorld
{
  MUWorld *world = [self _createTestWorld];
  MUPlayer *player = [self _createTestPlayerWithParentWorld: world];
  [world.children addObject: player];
  
  [_registry profileForWorld: world];
  [_registry profileForWorld: world player: player];
  [_registry removeAllProfilesForWorld: world];
  
  XCTAssertFalse ([_registry containsProfileForWorld: world], @"World only");
  XCTAssertFalse ([_registry containsProfileForWorld: world player: player], @"World and player");
}

#pragma mark - Private methods

- (void) _assertProfile: (MUProfile *) profile world: (MUWorld *) world player: (MUPlayer *) player
{
  XCTAssertNotNil (profile);
  XCTAssertEqualObjects (profile.world, world, @"World mismatch");
  XCTAssertEqualObjects (profile.player, player, @"Player mismatch");
}

- (MUWorld *) _createTestWorld
{
  return [[MUWorld alloc] initWithName: @"Test World" children: nil];
}

- (MUPlayer *) _createTestPlayerWithParentWorld: (MUWorld *) world
{
  MUPlayer *player = [MUPlayer playerWithName: @"User"];
  player.parent = world;
  
  return player;
}

@end
