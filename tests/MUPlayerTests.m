//
// MUPlayerTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUPlayerTests.h"
#import "MUPlayer.h"

@implementation MUPlayerTests

- (void) testLoginStringHasQuotesForMultiwordUsername
{
  MUPlayer *player = [MUPlayer playerWithName: @"My User"
  																	 password: @"password"];
  
  [self assert: player.loginString
        equals: @"connect \"My User\" password"];
}

- (void) testLoginStringHasNoQuotesForSingleWordUsername
{
  MUPlayer *player = [MUPlayer playerWithName: @"Bob"
  																	 password: @"drowssap"];
  [self assert: player.loginString
        equals: @"connect Bob drowssap"];
}

- (void) testLoginStringWithNilPassword
{
  MUPlayer *player = [MUPlayer playerWithName: @"guest"
  																	 password: nil];
  [self assert: player.loginString
  			equals: @"connect guest"];
}

- (void) testLoginStringWithZeroLengthPassword
{
  MUPlayer *player = [MUPlayer playerWithName: @"guest"
  																	 password: @""];
  [self assert: player.loginString
  			equals: @"connect guest"];
}

- (void) testNoLoginStringForNilPlayerName
{
  MUPlayer *playerOne = [MUPlayer playerWithName: nil
  																			password: nil];
  [self assertNil: playerOne.loginString];
  
  MUPlayer *playerTwo = [MUPlayer playerWithName: nil
  																			password: @"nonsense"];
  [self assertNil: playerTwo.loginString];
}

@end
