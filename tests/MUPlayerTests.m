//
// MUPlayerTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUPlayerTests.h"
#import "MUPlayer.h"

@implementation MUPlayerTests

- (void) setUp
{
  return;
}

- (void) tearDown
{
  return;
}

- (void) testLoginStringHasQuotesForMultiwordUsername
{
  MUWorld *testWorld = [MUWorld worldWithHostname: @"example.com" port: @4201];
  MUPlayer *testPlayer = [MUPlayer playerWithName: @"My User"];
  testPlayer.parent = testWorld;
  testPlayer.password = @"password";
  
  [self assert: testPlayer.loginString
        equals: @"connect \"My User\" password"];
  
  // Clean up after ourselves.
  testPlayer.password = nil;
  [self assert: testPlayer.loginString
        equals: @"connect \"My User\""];
  
}

- (void) testLoginStringHasNoQuotesForSingleWordUsername
{
  MUWorld *testWorld = [MUWorld worldWithHostname: @"example.com" port: @4201];
  MUPlayer *testPlayer = [MUPlayer playerWithName: @"Bob"];
  testPlayer.parent = testWorld;
  testPlayer.password = @"drowssap";
  
  [self assert: testPlayer.loginString
        equals: @"connect Bob drowssap"];
  
  // Clean up after ourselves.
  testPlayer.password = nil;
  [self assert: testPlayer.loginString
        equals: @"connect Bob"];
}

- (void) testLoginStringWithNoPassword
{
  MUPlayer *player = [MUPlayer playerWithName: @"guest"];
  [self assert: player.loginString
  			equals: @"connect guest"];
}

- (void) testNoLoginStringForNilPlayerName
{
  MUPlayer *playerOne = [MUPlayer playerWithName: nil];
  [self assertNil: playerOne.loginString];
}

@end
