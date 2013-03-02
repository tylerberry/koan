//
// MUProfileTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfileTests.h"
#import "MUProfile.h"

@implementation MUProfileTests

- (void) setUp
{
  return;
}

- (void) tearDown
{
  return;
}

- (void) testUniqueIdentifer
{
  MUWorld *world = [MUWorld worldWithHostname: @"example.com" port: @4201];
  
  MUProfile *profile = [MUProfile profileWithWorld: world];
  [self assert: profile.uniqueIdentifier equals: world.uniqueIdentifier];
  
  MUPlayer *player = [MUPlayer playerWithName: @"User"];
  player.parent = world;
  
  profile = [MUProfile profileWithWorld: world player: player];
  [self assert: profile.uniqueIdentifier equals: player.uniqueIdentifier];
}

- (void) testHasLoginInformation
{
  MUWorld *world = [MUWorld worldWithHostname: @"example.com" port: @4201];
  MUProfile *profile = [MUProfile profileWithWorld: world];
                    
  [self assertFalse: profile.hasLoginInformation message: @"no login info"];
                    
  MUPlayer *player = [MUPlayer playerWithName: @"User"];
  player.parent = world;
  profile.player = player;
                    
  [self assertTrue: profile.hasLoginInformation message: @"has login info"];
}

@end
