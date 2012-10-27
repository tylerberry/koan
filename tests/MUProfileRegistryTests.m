//
// MUProfileRegistryTest.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfileRegistryTests.h"
#import "MUProfileRegistry.h"
#import "MUProfile.h"
#import "MUWorld.h"

@interface MUProfileRegistryTests ()

- (void) assertProfile: (MUProfile *) profile
                 world: (MUWorld *) world
                player: (MUPlayer *) player;

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
  [self assertNotNil: registryOne];
  
  registryTwo = [MUProfileRegistry defaultRegistry];
  [self assert: registryOne equals: registryTwo];
}

- (void) testProfileWithWorld
{
  MUProfile *profileOne = nil;
  MUProfile *profileTwo = nil;
  MUWorld *world = [self testWorld];
  
  profileOne = [registry profileForWorld: world];
  [self assertProfile: profileOne world: world player: nil];
  
  profileTwo = [registry profileForUniqueIdentifier: @"world:test.world"];
  [self assert: profileTwo equals: profileOne message: @"First"];
  
  profileOne = [registry profileForWorld: world];
  [self assert: profileOne equals: profileTwo message: @"Second"];
  
}

- (void) testProfileWithWorldAndPlayer
{
  MUProfile *profileOne = nil, *profileTwo = nil;
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];
  
  profileOne = [registry profileForWorld: world player: player];
  [self assertProfile: profileOne world: world player: player];
  
  profileTwo = [registry profileForUniqueIdentifier: @"world:test.world;player:user"];
  [self assert: profileTwo equals: profileOne message: @"First"];
  
  profileOne = [registry profileForWorld: world player: player];
  [self assert: profileOne equals: profileTwo message: @"Second"];
}

- (void) testContains
{
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];
  
  [self assertFalse: [registry containsProfileForWorld: world player: player]
            message: @"Before adding"];
  
  [registry profileForWorld: world player: player];
  
  [self assertTrue: [registry containsProfileForWorld: world player: player]
           message: @"After adding"];
}

- (void) testRemove
{
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];

  [registry profileForWorld: world player: player];
  [self assertTrue: [registry containsProfileForWorld: world player: player]
           message: @"Before removing"];  
  
  [registry removeProfileForWorld: world player: player];  
  [self assertFalse: [registry containsProfileForWorld: world player: player]
            message: @"After removing"];

}

- (void) testRemoveWorld
{
  MUWorld *world = [self testWorld];
  MUPlayer *player = [self testPlayerWithParentWorld: world];
  [world.children addObject: player];
  
  [registry profileForWorld: world];
  [registry profileForWorld: world player: player];
  [registry removeAllProfilesForWorld: world];
  [self assertFalse: [registry containsProfileForWorld: world]
            message: @"World only"];
  [self assertFalse: [registry containsProfileForWorld: world
                                                player: player]
            message: @"World and player"];
}

#pragma mark - Private methods

- (void) assertProfile: (MUProfile *) profile
                 world: (MUWorld *) world
                player: (MUPlayer *) player
{
  [self assertNotNil: profile];
  [self assert: profile.world equals: world message: @"World mismatch"];
  [self assert: profile.player equals: player message: @"Player mismatch"];
}

- (MUWorld *) testWorld
{
  MUWorld *world = [[MUWorld alloc] init];
  world.name = @"Test World";
  return world;
}

- (MUPlayer *) testPlayerWithParentWorld: (MUWorld *) world
{
  MUPlayer *player = [MUPlayer playerWithName: @"User" password: @""];
  player.parent = world;
  
  return player;
}

@end
