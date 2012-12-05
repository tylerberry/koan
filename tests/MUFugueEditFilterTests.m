//
// MUFugueEditFilterTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFugueEditFilterTests.h"
#import "MUFugueEditFilter.h"

#import "MUPlayer.h"
#import "MUProfile.h"

@interface MUProfile (TestingFugueEdit)

+ (id) profileForTestingFugueEdit;
- (id) initForTestingFugueEdit;

@end

#pragma mark -

@implementation MUProfile (TestingFugueEdit)

+ (id) profileForTestingFugueEdit
{
  return [[self alloc] initForTestingFugueEdit];
}

- (id) initForTestingFugueEdit
{
  MUPlayer *player = [[MUPlayer alloc] init];
  
  player.fugueEditPrefix = @"FugueEdit > ";
  
  return [self initWithWorld: nil
                      player: player
                 autoconnect: NO
                        font: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]
             backgroundColor: nil
                   linkColor: nil
             systemTextColor: nil
                   textColor: nil];
}

@end

#pragma mark -

@implementation MUFugueEditFilterTests
{
  NSString *_editString;
}

- (void) setInputViewString: (NSString *) string
{
  _editString = [string copy];
}

- (void) setUp
{
  [super setUp];
  
  _editString = nil;
  
  [self.queue addFilter: [MUFugueEditFilter filterWithProfile: [MUProfile profileForTestingFugueEdit]
                                                     delegate: self]];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testIgnoresNormalInput
{
  [self assertInput: @"Just a normal line of text.\n" hasOutput: @"Just a normal line of text.\n"];
  [self assertNil: _editString]; 
}

- (void) testElidesFugueEdit
{
  [self assertInput: @"FugueEdit > &test me=Test\n" hasOutput: @""];
  [self assert: _editString equals: @"&test me=Test"];
}

@end
