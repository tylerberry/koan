//
// MUProfileRegistryTest.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfileRegistryTests.h"
#import "MUProfileRegistry.h"
#import "MUProfile.h"
#import "MUWorld.h"

@interface MUProfileRegistryTests ()

- (void) assertProfile: (MUProfile *) profile world: (MUWorld *) world player: (MUPlayer *) player;

- (MUWorld *) testWorld;
- (MUPlayer *) testPlayerWithParentWorld: (MUWorld *) world;

@end

#pragma mark -

@implementation MUProfileRegistryTests

- (void) setUp
{
  registry = [[MUProfileRegistry alloc] init];
}

- (void) tearDown
{
  return;
}

- (void) testSharedRegistry
{
  MUProfileRegistry *registryOne, *registryTwo;
  
  registryOne = [MUProfileRegistry defaultRegistry];
  XCTAssertNotNil (registryOne);
  
  registryTwo = [MUProfileRegistry defaultRegistry];
  XCTAssertEqualObjects (registryOne, registryTwo);
}

- (void) testProfileWithWorld
{
  MUProfile *profileOne = nil;
  MUProfile *profileTwo = nil;
  MUWorld *world = [self testWorld];
  
  profileOne = [registry profileForWorld: world];
  [self assertProfile: profileOne world: world player: nil];
  
  profileTwo = [registry profileForUniqueIdentifier: world.uniqueIdentifier];
  XCTAssertEqualObjects (profileTwo, profileOne, @"First");
  
  profileOne = [registry profileForWorld: world];
  XCTAssertEqualObjects (profileOne, profileTwo, @"Second");
}

- (void) testProfileWithWorldAndPlayer
{
  MUProfile *profileOne = nil, *profileTwo = nil;
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];
  
  profileOne = [registry profileForWorld: world player: player];
  [self assertProfile: profileOne world: world player: player];
  
  profileTwo = [registry profileForUniqueIdentifier: player.uniqueIdentifier];
  XCTAssertEqualObjects (profileTwo, profileOne, @"First");
  
  profileOne = [registry profileForWorld: world player: player];
  XCTAssertEqualObjects (profileOne, profileTwo, @"Second");
}

- (void) testContains
{
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];
  
  XCTAssertFalse ([registry containsProfileForWorld: world player: player], @"Before adding");
  
  [registry profileForWorld: world player: player];
  
  XCTAssertTrue ([registry containsProfileForWorld: world player: player], @"After adding");
}

- (void) testRemove
{
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];

  [registry profileForWorld: world player: player];
  XCTAssertTrue ([registry containsProfileForWorld: world player: player], @"Before removing");
  
  [registry removeProfileForWorld: world player: player];  
  XCTAssertFalse ([registry containsProfileForWorld: world player: player], @"After removing");

}

- (void) testRemoveWorld
{
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];
  [world.children addObject: player];
  
  [registry profileForWorld: world];
  [registry profileForWorld: world player: player];
  [registry removeAllProfilesForWorld: world];
  
  XCTAssertFalse ([registry containsProfileForWorld: world], @"World only");
  XCTAssertFalse ([registry containsProfileForWorld: world player: player], @"World and player");
}

#pragma mark - Private methods

- (void) assertProfile: (MUProfile *) profile world: (MUWorld *) world player: (MUPlayer *) player
{
  XCTAssertNotNil (profile);
  XCTAssertEqualObjects (profile.world, world, @"World mismatch");
  XCTAssertEqualObjects (profile.player, player, @"Player mismatch");
}

- (MUWorld *) testWorld
{
  MUWorld *world = [[MUWorld alloc] init];
  world.name = @"Test World";
  return world;
}

- (MUPlayer *) testPlayerWithParentWorld: (MUWorld *) world
{
  MUPlayer *player = [MUPlayer playerWithName: @"User"];
  player.parent = world;
  
  return player;
}

@end
