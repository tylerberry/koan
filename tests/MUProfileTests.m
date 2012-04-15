//
// MUProfileTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfileTests.h"
#import "MUProfile.h"

@implementation MUProfileTests

- (void) testUniqueIdentifer
{
  MUWorld *world = [[MUWorld alloc] init];
  world.name = @"Test World";
  
  MUProfile *profile = [MUProfile profileWithWorld: world];
  [self assert: profile.uniqueIdentifier equals: @"world:test.world"];
  
  MUPlayer *player = [MUPlayer playerWithName: @"User" password: @""];
  player.parent = world;
  
  profile = [MUProfile profileWithWorld: world player: player];
  [self assert: profile.uniqueIdentifier equals: @"world:test.world;player:user"];
}

- (void) testHasLoginInformation
{
  MUWorld *world = [[MUWorld alloc] init];
  world.name = @"Test World";
  MUProfile *profile = [MUProfile profileWithWorld: world];
  [self assertFalse: [profile hasLoginInformation] message: @"no login info"];
  MUPlayer *player = [MUPlayer playerWithName: @"User" password: @"foo"];
  player.parent = world;
  profile.player = player;
  [self assertTrue: [profile hasLoginInformation] message: @"has login info"];
}

@end
