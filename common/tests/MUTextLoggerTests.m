//
// MUTextLoggerTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLogger.h"

#define MUTEXTLOG_BUFFER_MAX 1024

@interface MUTextLoggerTests : XCTestCase

- (void) _assertFilterAttributedString: (NSAttributedString *) attributedString;
- (void) _assertFilterString: (NSString *) string;
- (void) _assertLoggedOutput: (NSString *) string;

@end

#pragma mark -

@implementation MUTextLoggerTests
{
  MUTextLogger *_textLogger;
  uint8_t _outputBuffer[MUTEXTLOG_BUFFER_MAX];
}

- (void) setUp
{
  [super setUp];

  memset (_outputBuffer, 0, MUTEXTLOG_BUFFER_MAX);
  NSOutputStream *outputStream = [NSOutputStream outputStreamToBuffer: _outputBuffer
                                                             capacity: MUTEXTLOG_BUFFER_MAX];
  [outputStream open];
  
  _textLogger = [[MUTextLogger alloc] initWithOutputStream: outputStream];
}

- (void) tearDown
{
  memset (_outputBuffer, 0, MUTEXTLOG_BUFFER_MAX);
  _textLogger = nil;

  [super tearDown];
}

- (void) testEmptyString
{
  [self _assertFilterString: @""];
  [self _assertLoggedOutput: @""];
}

- (void) testSimpleString
{
  [self _assertFilterString: @"Foo"];
  [self _assertLoggedOutput: @"Foo"];
}

- (void) testColorString
{
  NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor redColor]};
  NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString: @"Foo" attributes: attributes];
  
  [self _assertFilterAttributedString: string];
  [self _assertLoggedOutput: @"Foo"];
}

- (void) testFontString
{
  NSDictionary *attributes = @{NSFontAttributeName: [NSFont fontWithName: @"Monaco" size: 10.0]};
  NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString: @"Foo" attributes: attributes];

  [self _assertFilterAttributedString: string];
  [self _assertLoggedOutput: @"Foo"];
}

- (void) testSimpleConcatenation
{
  [self _assertFilterString: @"One"];
  [self _assertFilterString: @" "];
  [self _assertFilterString: @"Two"];
  [self _assertLoggedOutput: @"One Two"];
}

- (void) testEmptyStringConcatenation
{
  [self _assertFilterString: @"One"];
  [self _assertFilterString: @""];
  [self _assertFilterString: @"Two"];
  [self _assertLoggedOutput: @"OneTwo"];
}

- (void) testComplexEmptyStringConcatenation
{
  NSMutableAttributedString *one = [[NSMutableAttributedString alloc] initWithString: @"One"];
  NSMutableAttributedString *two = [[NSMutableAttributedString alloc] initWithString: @"Two"];
  NSMutableAttributedString *empty = [[NSMutableAttributedString alloc] initWithString: @""];
  
  [one addAttribute: NSForegroundColorAttributeName
              value: [NSColor redColor]
              range: NSMakeRange (0, [one length])];
  
  [two addAttribute: NSFontAttributeName
              value: [NSFont fontWithName: @"Monaco" size: 10.0]
              range: NSMakeRange (0, [two length])];
  
  [empty addAttribute: NSForegroundColorAttributeName
                value: [NSColor greenColor]
                range: NSMakeRange (0, [empty length])];
  
  [self _assertFilterAttributedString: one];
  [self _assertFilterAttributedString: empty];
  [self _assertFilterAttributedString: two];
  [self _assertLoggedOutput: @"OneTwo"];
}

#pragma mark - Private methods

- (void) _assertFilterAttributedString: (NSAttributedString *) attributedString
{
  XCTAssertEqualObjects ([_textLogger filterCompleteLine: attributedString], attributedString);
}

- (void) _assertFilterString: (NSString *) string
{
  [self _assertFilterAttributedString: [[NSAttributedString alloc] initWithString: string]];
}

- (void) _assertLoggedOutput: (NSString *) string
{
  NSString *outputString = @((const char *) _outputBuffer);
  
  XCTAssertEqualObjects (outputString, string);
}

@end
