//
// MUFugueEditFilterTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilterTestCase.h"

#import "MUFugueEditFilter.h"
#import "MUPlayer.h"
#import "MUProfile.h"

@interface MUProfile (TestingFugueEdit)

+ (instancetype) _profileForTestingFugueEdit;
- (instancetype) _initForTestingFugueEdit;

@end

#pragma mark -

@implementation MUProfile (TestingFugueEdit)

+ (instancetype) _profileForTestingFugueEdit
{
  return [[self alloc] _initForTestingFugueEdit];
}

- (instancetype) _initForTestingFugueEdit
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

@interface MUFugueEditFilterTests : MUFilterTestCase <MUFugueEditFilterDelegate>

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
  
  [self.queue addFilter: [MUFugueEditFilter filterWithProfile: [MUProfile _profileForTestingFugueEdit]
                                                     delegate: self]];
}

- (void) tearDown
{
  _editString = nil;
  [super tearDown];
}

- (void) testIgnoresNormalInput
{
  [self assertInput: @"Just a normal line of text.\n" hasOutput: @"Just a normal line of text.\n"];
  XCTAssertNil (_editString);
}

- (void) testElidesFugueEdit
{
  [self assertInput: @"FugueEdit > &test me=Test\n" hasOutput: @""];
  XCTAssertNotNil (_editString);
  XCTAssertEqualObjects (_editString, @"&test me=Test");
}

@end
