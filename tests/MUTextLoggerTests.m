//
// MUTextLoggerTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextLoggerTests.h"

#define MUTEXTLOG_BUFFER_MAX 1024

@interface MUTextLoggerTests ()
{
  MUTextLogger *_textLogger;
  uint8_t _outputBuffer[MUTEXTLOG_BUFFER_MAX];
}

- (void) assertFilter: (id) object;
- (void) assertFilterString: (NSString *) string;
- (void) assertLoggedOutput: (NSString *) string;

@end

#pragma mark -

@implementation MUTextLoggerTests

- (void) setUp
{
  memset (_outputBuffer, 0, MUTEXTLOG_BUFFER_MAX);
  NSOutputStream *outputStream = [NSOutputStream outputStreamToBuffer: _outputBuffer
                                                             capacity: MUTEXTLOG_BUFFER_MAX];
  [outputStream open];
  
  _textLogger = [[MUTextLogger alloc] initWithOutputStream: outputStream];
}

- (void) tearDown
{
  _textLogger = nil;
}

- (void) testEmptyString
{
  [self assertFilterString: @""];
  [self assertLoggedOutput: @""];
}

- (void) testSimpleString
{
  [self assertFilterString: @"Foo"];
  [self assertLoggedOutput: @"Foo"];
}

- (void) testColorString
{
  NSMutableAttributedString *string = [NSMutableAttributedString attributedStringWithString: @"Foo"];
  [string addAttribute: NSForegroundColorAttributeName
                 value: [NSColor redColor]
                 range: NSMakeRange (0, [string length])];
  
  [self assertFilter: string];
  [self assertLoggedOutput: @"Foo"];
}

- (void) testFontString
{
  NSMutableAttributedString *string = [NSMutableAttributedString attributedStringWithString: @"Foo"];
  [string addAttribute: NSFontAttributeName
                 value: [NSFont fontWithName: @"Monaco" size: 10.0]
                 range: NSMakeRange (0, [string length])];
  
  [self assertFilter: string];
  [self assertLoggedOutput: @"Foo"];
}

- (void) testSimpleConcatenation
{
  [self assertFilterString: @"One"];
  [self assertFilterString: @" "];
  [self assertFilterString: @"Two"];
  [self assertLoggedOutput: @"One Two"];
}

- (void) testEmptyStringConcatenation
{
  [self assertFilterString: @"One"];
  [self assertFilterString: @""];
  [self assertFilterString: @"Two"];
  [self assertLoggedOutput: @"OneTwo"];
}

- (void) testComplexEmptyStringConcatenation
{
  NSMutableAttributedString *one = [NSMutableAttributedString attributedStringWithString: @"One"];
  NSMutableAttributedString *two = [NSMutableAttributedString attributedStringWithString: @"Two"];
  NSMutableAttributedString *empty = [NSMutableAttributedString attributedStringWithString: @""];
  
  [one addAttribute: NSForegroundColorAttributeName
              value: [NSColor redColor]
              range: NSMakeRange (0, [one length])];
  
  [two addAttribute: NSFontAttributeName
              value: [NSFont fontWithName: @"Monaco" size: 10.0]
              range: NSMakeRange (0, [two length])];
  
  [empty addAttribute: NSForegroundColorAttributeName
                value: [NSColor greenColor]
                range: NSMakeRange (0, [empty length])];
  
  [self assertFilter: one];
  [self assertFilter: empty];
  [self assertFilter: two];
  [self assertLoggedOutput: @"OneTwo"];
}

#pragma mark - Private methods

- (void) assertFilter: (id) object
{
  [self assert: [_textLogger filterCompleteLine: object] equals: object message: nil];
}

- (void) assertFilterString: (NSString *) string
{
  [self assertFilter: [NSAttributedString attributedStringWithString: string]];
}

- (void) assertLoggedOutput: (NSString *) string
{
  NSString *outputString = @((const char *) _outputBuffer);
  
  [self assert: outputString equals: string];
}

@end
