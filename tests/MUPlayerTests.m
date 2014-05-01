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
  MUWorld *testWorld = [MUWorld worldWithHostname: @"example.com" port: @4201 forceTLS: NO];
  MUPlayer *testPlayer = [MUPlayer playerWithName: @"My User"];
  testPlayer.parent = testWorld;
  testPlayer.password = @"password";
  
  XCTAssertEqualObjects (testPlayer.loginString, @"connect \"My User\" password");
  
  // Clean up after ourselves.
  testPlayer.password = nil;
  XCTAssertEqualObjects (testPlayer.loginString, @"connect \"My User\"");
  
}

- (void) testLoginStringHasNoQuotesForSingleWordUsername
{
  MUWorld *testWorld = [MUWorld worldWithHostname: @"example.com" port: @4201 forceTLS: NO];
  MUPlayer *testPlayer = [MUPlayer playerWithName: @"Bob"];
  testPlayer.parent = testWorld;
  testPlayer.password = @"drowssap";
  
  XCTAssertEqualObjects (testPlayer.loginString, @"connect Bob drowssap");
  
  // Clean up after ourselves.
  testPlayer.password = nil;
  XCTAssertEqualObjects (testPlayer.loginString, @"connect Bob");
}

- (void) testLoginStringWithNoPassword
{
  MUPlayer *player = [MUPlayer playerWithName: @"guest"];
  XCTAssertEqualObjects (player.loginString, @"connect guest");
}

- (void) testNoLoginStringForNilPlayerName
{
  MUPlayer *playerOne = [MUPlayer playerWithName: nil];
  XCTAssertNil (playerOne.loginString);
}

@end
