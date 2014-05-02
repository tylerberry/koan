//
// MUProfileTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfile.h"

@interface MUProfileTests : XCTestCase

@end

#pragma mark -

@implementation MUProfileTests

- (void) setUp
{
  [super setUp];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testUniqueIdentifer
{
  MUWorld *world = [MUWorld worldWithHostname: @"example.com" port: @4201 forceTLS: NO];
  
  MUProfile *profile = [MUProfile profileWithWorld: world];
  XCTAssertEqualObjects (profile.uniqueIdentifier, world.uniqueIdentifier);
  
  MUPlayer *player = [MUPlayer playerWithName: @"User"];
  player.parent = world;
  
  profile = [MUProfile profileWithWorld: world player: player];
  XCTAssertEqualObjects (profile.uniqueIdentifier, player.uniqueIdentifier);
}

- (void) testHasLoginInformation
{
  MUWorld *world = [MUWorld worldWithHostname: @"example.com" port: @4201 forceTLS: NO];
  MUProfile *profile = [MUProfile profileWithWorld: world];
                    
  XCTAssertFalse (profile.hasLoginInformation, @"no login info");
                    
  MUPlayer *player = [MUPlayer playerWithName: @"User"];
  player.parent = world;
  profile.player = player;
                    
  XCTAssertTrue (profile.hasLoginInformation, @"has login info");
}

@end
