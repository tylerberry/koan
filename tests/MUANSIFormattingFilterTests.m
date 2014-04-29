//
// MUANSIFormattingFilterTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUANSIFormattingFilterTests.h"
#import "MUANSIFormattingFilter.h"
#import "MUProfile.h"
#import "NSColor+ANSI.h"
#import "NSFont+Traits.h"

#define TESTING_BACKGROUND_COLOR [NSColor redColor]
#define TESTING_LINK_COLOR [NSColor yellowColor]
#define TESTING_SYSTEM_TEXT_COLOR [NSColor darkGrayColor]
#define TESTING_TEXT_COLOR [NSColor purpleColor]

#define COLOR(c) [NSUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] dataForKey:(c)]]

@interface MUProfile (TestingANSI)

+ (id) profileForTestingANSI;

@end

#pragma mark -

@implementation MUProfile (TestingANSI)

+ (id) profileForTestingANSI
{
  return [[self alloc] initWithWorld: nil
                              player: nil
                         autoconnect: NO
                                font: [NSFont fontWithName: @"Courier New" size: 12.0]
                     backgroundColor: TESTING_BACKGROUND_COLOR
                           linkColor: TESTING_LINK_COLOR
                     systemTextColor: TESTING_SYSTEM_TEXT_COLOR
                           textColor: TESTING_TEXT_COLOR];
}

@end

#pragma mark -

@interface MUANSIFormattingFilterTests ()

- (void) assertFinalCharacter: (unsigned char) finalChar;
- (void) assertString: (NSAttributedString *) string
             hasValue: (id) value
         forAttribute: (NSString *) attribute
              atIndex: (int) characterIndex
              message: (NSString *) message;
- (void) assertString: (NSAttributedString *) string
             hasTrait: (NSFontTraitMask) trait
              atIndex: (int) characterIndex
              message: (NSString *) message;
- (void) assertString: (NSAttributedString *) string
           hasntTrait: (NSFontTraitMask) trait
              atIndex: (int) characterIndex
              message: (NSString *) message;

@end

#pragma mark -

@implementation MUANSIFormattingFilterTests

- (void) setUp
{
  [super setUp];
  
  [self.queue addFilter: [MUANSIFormattingFilter filterWithProfile: [MUProfile profileForTestingANSI]
                                                          delegate: nil]];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testNoCode
{
  [self assertInput: @"Foo"
          hasOutput: @"Foo"];
}

- (void) testSingleCharacter
{
  [self assertInput: @"Q"
          hasOutput: @"Q"];
}

- (void) testBasicCode
{
  [self assertInput: @"F\x1B[moo"
          hasOutput: @"Foo"
            message: @"One"];
  [self assertInput: @"F\x1B[3moo"
          hasOutput: @"Foo"
            message: @"Two"];
  [self assertInput: @"F\x1B[36moo"
          hasOutput: @"Foo"
            message: @"Three"];
}

- (void) testTwoCodes
{
  [self assertInput: @"F\x1B[36moa\x1B[3mob"
          hasOutput: @"Foaob"];
}

- (void) testCompoundCode
{
  [self assertInput: @"F\x1B[0;1;3;32;45moo"
          hasOutput: @"Foo"];
}

- (void) testNewLine
{
  [self assertInput: @"Foo\n"
          hasOutput: @"Foo\n"];
}

- (void) testOnlyNewLine
{
  [self assertInput: @"\n"
          hasOutput: @"\n"];
}

- (void) testCodeAtEndOfLine
{
  [self assertInput: @"Foo\x1B[36m\n"
          hasOutput: @"Foo\n"];
}

- (void) testCodeAtBeginningOfString
{
  [self assertInput: @"\x1B[36mFoo"
          hasOutput: @"Foo"];
}

- (void) testCodeAtEndOfString
{
  [self assertInput: @"Foo\x1B[36m"
          hasOutput: @"Foo"];
}

- (void) testEmptyString
{
  [self assertInput: @""
          hasOutput: @""];
}

- (void) testOnlyCode
{
  [self assertInput: @"\x1B[36m"
          hasOutput: @""];
}

- (void) testCodeSplitOverTwoStrings
{
  [self assertInput: @"\x1B[" hasOutput: @""];
  [self assertInput: @"36m" hasOutput: @""];
}

- (void) testCodeWithJustTerminatorInSecondString
{
  [self assertInput: @"\x1B[36" hasOutput: @""];
  [self assertInput: @"m" hasOutput: @""];
}

- (void) testLongString
{
  NSString *longString =
    @"        #@@N         (@@)     (@@@)        J@@@@F      @@@@@@@L";
  [self assertInput: longString
          hasOutput: longString];
}

- (void) testOnlyWhitespaceBeforeCodeAndNothingAfterIt
{
  [self assertInput: @" \x1B[1m"
          hasOutput: @" "];
}

- (void) testForegroundColor
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[36mbc\x1B[35md\x1B[39me"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 3
             message: @"d"];
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 4
             message: @"e"];
}

- (void) testStandardForegroundColors
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[30ma\x1B[31mb\x1B[32mc\x1B[33md\x1B[34me\x1B[35mf\x1B[36mg\x1B[37mh"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIBlackColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a"];
  [self assertString: output
            hasValue: COLOR (MUPANSIRedColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b"];
  [self assertString: output
            hasValue: COLOR (MUPANSIGreenColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c"];
  [self assertString: output
            hasValue: COLOR (MUPANSIYellowColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 3
             message: @"d"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBlueColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 4
             message: @"e"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 5
             message: @"f"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 6
             message: @"g"];
  [self assertString: output
            hasValue: COLOR (MUPANSIWhiteColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 7
             message: @"h"];
}

- (void) testXTerm256ForegroundColor
{
  for (unsigned i = 0; i < 16; i++)
  {
    NSAttributedString *input = [self constructAttributedStringForString: [NSString stringWithFormat: @"\x1B[38;5;%dm%d", i, i]];
    NSAttributedString *output = [self.queue processCompleteLine: input];
    
    NSColor *targetColor;
    
    switch (i)
    {
      case MUANSI256Black:
        targetColor = COLOR (MUPANSIBlackColor);
        break;
        
      case MUANSI256BrightBlack:
        targetColor = COLOR (MUPANSIBrightBlackColor);
        break;
        
      case MUANSI256Red:
        targetColor = COLOR (MUPANSIRedColor);
        break;
        
      case MUANSI256BrightRed:
        targetColor = COLOR (MUPANSIBrightRedColor);
        break;
        
      case MUANSI256Green:
        targetColor = COLOR (MUPANSIGreenColor);
        break;
        
      case MUANSI256BrightGreen:
        targetColor = COLOR (MUPANSIBrightGreenColor);
        break;
        
      case MUANSI256Yellow:
        targetColor = COLOR (MUPANSIYellowColor);
        break;
        
      case MUANSI256BrightYellow:
        targetColor = COLOR (MUPANSIBrightYellowColor);
        break;
        
      case MUANSI256Blue:
        targetColor = COLOR (MUPANSIBlueColor);
        break;
        
      case MUANSI256BrightBlue:
        targetColor = COLOR (MUPANSIBrightBlueColor);
        break;
        
      case MUANSI256Magenta:
        targetColor = COLOR (MUPANSIMagentaColor);
        break;
        
      case MUANSI256BrightMagenta:
        targetColor = COLOR (MUPANSIBrightMagentaColor);
        break;
        
      case MUANSI256Cyan:
        targetColor = COLOR (MUPANSICyanColor);
        break;
        
      case MUANSI256BrightCyan:
        targetColor = COLOR (MUPANSIBrightCyanColor);
        break;
        
      case MUANSI256White:
        targetColor = COLOR (MUPANSIWhiteColor);
        break;
        
      case MUANSI256BrightWhite:
        targetColor = COLOR (MUPANSIBrightWhiteColor);
        break;
    }
    
    [self assertString: output
              hasValue: targetColor
          forAttribute: NSForegroundColorAttributeName
               atIndex: 0
               message: [NSString stringWithFormat: @"%d", i]];
  }
  
  for (uint16_t i = 16; i < 232; i++)
  {
    NSAttributedString *input = [self constructAttributedStringForString: [NSString stringWithFormat: @"\x1B[38;5;%dm%d", i, i]];
    NSAttributedString *output = [self.queue processCompleteLine: input];
    
    NSColor *expectedColor = [NSColor ANSI256ColorCubeColorForCode: (uint8_t) i];
    
    [self assertString: output
              hasValue: expectedColor
          forAttribute: NSForegroundColorAttributeName
               atIndex: 0
               message: [NSString stringWithFormat: @"%d", i]];
  }
  
  for (uint16_t i = 232; i < 256; i++)
  {
    NSAttributedString *input = [self constructAttributedStringForString: [NSString stringWithFormat: @"\x1B[38;5;%dm%d", i, i]];
    NSAttributedString *output = [self.queue processCompleteLine: input];
    
    NSColor *expectedColor = [NSColor ANSI256GrayscaleColorForCode: (uint8_t) i];
    
    [self assertString: output
              hasValue: expectedColor
          forAttribute: NSForegroundColorAttributeName
               atIndex: 0
               message: [NSString stringWithFormat: @"%d", i]];
  }
}

- (void) testBackgroundColor
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[46mbc\x1B[45md\x1B[49me"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 0
             message: @"a"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 2
             message: @"c"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 3
             message: @"d"];
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 4
             message: @"e"];
}

- (void) testStandardBackgroundColors
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[40ma\x1B[41mb\x1B[42mc\x1B[43md\x1B[44me\x1B[45mf\x1B[46mg\x1B[47mh"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIBlackColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 0
             message: @"a"];
  [self assertString: output
            hasValue: COLOR (MUPANSIRedColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b"];
  [self assertString: output
            hasValue: COLOR (MUPANSIGreenColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 2
             message: @"c"];
  [self assertString: output
            hasValue: COLOR (MUPANSIYellowColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 3
             message: @"d"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBlueColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 4
             message: @"e"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 5
             message: @"f"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 6
             message: @"g"];
  [self assertString: output
            hasValue: COLOR (MUPANSIWhiteColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 7
             message: @"h"];
}

- (void) testXTerm256BackgroundColor
{
  for (unsigned i = 0; i < 16; i++)
  {
    NSAttributedString *input = [self constructAttributedStringForString: [NSString stringWithFormat: @"\x1B[48;5;%dm%d", i, i]];
    NSAttributedString *output = [self.queue processCompleteLine: input];
    
    NSColor *targetColor;
    
    switch (i)
    {
      case MUANSI256Black:
        targetColor = COLOR (MUPANSIBlackColor);
        break;
        
      case MUANSI256BrightBlack:
        targetColor = COLOR (MUPANSIBrightBlackColor);
        break;
        
      case MUANSI256Red:
        targetColor = COLOR (MUPANSIRedColor);
        break;
        
      case MUANSI256BrightRed:
        targetColor = COLOR (MUPANSIBrightRedColor);
        break;
        
      case MUANSI256Green:
        targetColor = COLOR (MUPANSIGreenColor);
        break;
        
      case MUANSI256BrightGreen:
        targetColor = COLOR (MUPANSIBrightGreenColor);
        break;
        
      case MUANSI256Yellow:
        targetColor = COLOR (MUPANSIYellowColor);
        break;
        
      case MUANSI256BrightYellow:
        targetColor = COLOR (MUPANSIBrightYellowColor);
        break;
        
      case MUANSI256Blue:
        targetColor = COLOR (MUPANSIBlueColor);
        break;
        
      case MUANSI256BrightBlue:
        targetColor = COLOR (MUPANSIBrightBlueColor);
        break;
        
      case MUANSI256Magenta:
        targetColor = COLOR (MUPANSIMagentaColor);
        break;
        
      case MUANSI256BrightMagenta:
        targetColor = COLOR (MUPANSIBrightMagentaColor);
        break;
        
      case MUANSI256Cyan:
        targetColor = COLOR (MUPANSICyanColor);
        break;
        
      case MUANSI256BrightCyan:
        targetColor = COLOR (MUPANSIBrightCyanColor);
        break;
        
      case MUANSI256White:
        targetColor = COLOR (MUPANSIWhiteColor);
        break;
        
      case MUANSI256BrightWhite:
        targetColor = COLOR (MUPANSIBrightWhiteColor);
        break;
    }
    
    [self assertString: output
              hasValue: targetColor
          forAttribute: NSBackgroundColorAttributeName
               atIndex: 0
               message: [NSString stringWithFormat: @"%d", i]];
  }
  
  for (uint16_t i = 16; i < 232; i++)
  {
    NSAttributedString *input = [self constructAttributedStringForString: [NSString stringWithFormat: @"\x1B[48;5;%dm%d", i, i]];
    NSAttributedString *output = [self.queue processCompleteLine: input];
    
    NSColor *expectedColor = [NSColor ANSI256ColorCubeColorForCode: (uint8_t) i];
    
    [self assertString: output
              hasValue: expectedColor
          forAttribute: NSBackgroundColorAttributeName
               atIndex: 0
               message: [NSString stringWithFormat: @"%d", i]];
  }
  
  for (uint16_t i = 232; i < 256; i++)
  {
    NSAttributedString *input = [self constructAttributedStringForString: [NSString stringWithFormat: @"\x1B[48;5;%dm%d", i, i]];
    NSAttributedString *output = [self.queue processCompleteLine: input];
    
    NSColor *expectedColor = [NSColor ANSI256GrayscaleColorForCode: (uint8_t) i];
    
    [self assertString: output
              hasValue: expectedColor
          forAttribute: NSBackgroundColorAttributeName
               atIndex: 0
               message: [NSString stringWithFormat: @"%d", i]];
  }
}

- (void) testForegroundAndBackgroundColorAsCompoundCode
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[36;46mbc\x1B[45;35md\x1B[39;49me"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 0
             message: @"a background"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b background"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 2
             message: @"c background"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 3
             message: @"d foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 3
             message: @"d background"];
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 4
             message: @"e foreground"];
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 4
             message: @"e background"];
}

- (void) testResetDisplayMode
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[36m\x1B[46mb\x1B[0mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b background"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 2
             message: @"c background"];
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testCompoundSetThenResetDisplayMode
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[36;46mb\x1B[0mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b background"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName atIndex: 2
             message: @"c background"];
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testShortFormOfResetDisplayMode
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[36m\x1B[46mb\x1B[mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b background"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 2
             message: @"c background"];
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testMidCodeResetDisplayMode
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[36;46;0mb"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSBackgroundColorAttributeName
             atIndex: 1
             message: @"b background"];
  [self assertString: output
            hasValue: TESTING_TEXT_COLOR
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
}

- (void) testPersistColorsBetweenLines
{
  NSAttributedString *firstInput = [self constructAttributedStringForString: @"a\x1B[36mb"];
  NSAttributedString *secondInput = [self constructAttributedStringForString: @"c"];
  NSAttributedString *output;
  
  [self.queue processCompleteLine: firstInput];
  output = [self.queue processCompleteLine: secondInput];
  
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"c"];
}

- (void) testBold
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[1mb\x1B[22mc\x1B[1md\x1B[0me\x1B[1mf\x1B[mg"];
  NSAttributedString *output = [self.queue processCompleteLine: input];

  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 0 message: @"a"];
  [self assertString: output hasValue: @YES forAttribute: MUBoldFontAttributeName atIndex: 1 message: @"b"];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 2 message: @"c"];
  [self assertString: output hasValue: @YES forAttribute: MUBoldFontAttributeName atIndex: 3 message: @"d"];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 4 message: @"e"];
  [self assertString: output hasValue: @YES forAttribute: MUBoldFontAttributeName atIndex: 5 message: @"f"];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 6 message: @"g"];
}

- (void) testBoldBrightBlackColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[30ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIBlackColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightBlackColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBlackColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightRedColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[31ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIRedColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightRedColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIRedColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightGreenColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[32ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIGreenColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightGreenColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIGreenColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightYellowColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[33ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIYellowColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightYellowColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIYellowColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightBlueColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[34ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIBlueColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightBlueColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBlueColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightMagentaColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[35ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightMagentaColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIMagentaColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightCyanColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[36ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightCyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSICyanColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldBrightWhiteColorChanges
{
  NSAttributedString *input = [self constructAttributedStringForString: @"\x1B[37ma\x1B[1mb\x1B[22mc"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: COLOR (MUPANSIWhiteColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 0
             message: @"a foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIBrightWhiteColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 1
             message: @"b foreground"];
  [self assertString: output
            hasValue: COLOR (MUPANSIWhiteColor)
        forAttribute: NSForegroundColorAttributeName
             atIndex: 2
             message: @"c foreground"];
}

- (void) testBoldWithBoldAlreadyOn
{
  NSMutableAttributedString *input = [self constructAttributedStringForString: @"a\x1B[1mb\x1B[22mc\x1B[1md\x1B[0me\x1B[1mf\x1B[mg"];
  NSAttributedString *output;
  
  [self.queue clearFilters];
  
  MUProfile *testingProfile = [MUProfile profileForTestingANSI];
  testingProfile.font = [[NSFontManager sharedFontManager] convertFont: testingProfile.font toHaveTrait: NSBoldFontMask];
  [self.queue addFilter: [MUANSIFormattingFilter filterWithProfile: testingProfile delegate: nil]];

  output = [self.queue processCompleteLine: input];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 0 message: @"a"];
  [self assertString: output hasValue: @YES forAttribute: MUBoldFontAttributeName atIndex: 1 message: @"b"];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 2 message: @"c"];
  [self assertString: output hasValue: @YES forAttribute: MUBoldFontAttributeName atIndex: 3 message: @"d"];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 4 message: @"e"];
  [self assertString: output hasValue: @YES forAttribute: MUBoldFontAttributeName atIndex: 5 message: @"f"];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 6 message: @"g"];
  
  output = [self.queue processCompleteLine: input];
  [self assertString: output hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 0 message: @"a2"];
}

- (void) testItalic
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[3mb\x1B[23mc\x1B[3md\x1B[0me\x1B[3mf\x1B[mg"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 0 message: @"a"];
  [self assertString: output hasntTrait: NSItalicFontMask atIndex: 0 message: @"a trait"];
  [self assertString: output hasValue: @YES forAttribute: MUItalicFontAttributeName atIndex: 1 message: @"b"];
  [self assertString: output hasTrait: NSItalicFontMask atIndex: 1 message: @"b trait"];
  [self assertString: output hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 2 message: @"c"];
  [self assertString: output hasntTrait: NSItalicFontMask atIndex: 2 message: @"c trait"];
  [self assertString: output hasValue: @YES forAttribute: MUItalicFontAttributeName atIndex: 3 message: @"d"];
  [self assertString: output hasTrait: NSItalicFontMask atIndex: 3 message: @"d trait"];
  [self assertString: output hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 4 message: @"e"];
  [self assertString: output hasntTrait: NSItalicFontMask atIndex: 4 message: @"e trait"];
  [self assertString: output hasValue: @YES forAttribute: MUItalicFontAttributeName atIndex: 5 message: @"f"];
  [self assertString: output hasTrait: NSItalicFontMask atIndex: 5 message: @"f trait"];
  [self assertString: output hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 6 message: @"g"];
  [self assertString: output hasntTrait: NSItalicFontMask atIndex: 6 message: @"g trait"];
}

- (void) testUnderline
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[4mb\x1B[24mc\x1B[4md\x1B[0me\x1B[4mf\x1B[mg"];  
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 0
             message: @"a"];
  
  [self assertString: output
            hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 1
             message: @"b"];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 2
             message: @"c"];
  
  [self assertString: output
            hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 3
             message: @"d"];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 4
             message: @"e"];
  
  [self assertString: output
            hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 5
             message: @"f"];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 6
             message: @"g"];
}

- (void) testDoubleUnderline
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[21mb\x1B[24mc\x1B[21md\x1B[0me\x1B[21mf\x1B[mg"];
  NSAttributedString *output = [self.queue processCompleteLine: input];

  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 0
             message: @"a"];

  [self assertString: output
            hasValue: @(NSUnderlineStyleDouble)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 1
             message: @"b"];

  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 2
             message: @"c"];

  [self assertString: output
            hasValue: @(NSUnderlineStyleDouble)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 3
             message: @"d"];

  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 4
             message: @"e"];

  [self assertString: output
            hasValue: @(NSUnderlineStyleDouble)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 5
             message: @"f"];

  [self assertString: output
            hasValue: nil
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 6
             message: @"g"];
}

- (void) testStrikethrough
{
  NSAttributedString *input = [self constructAttributedStringForString: @"a\x1B[9mb\x1B[29mc\x1B[9md\x1B[0me\x1B[9mf\x1B[mg"];
  NSAttributedString *output = [self.queue processCompleteLine: input];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 0
             message: @"a"];
  
  [self assertString: output
            hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 1
             message: @"b"];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 2
             message: @"c"];
  
  [self assertString: output
            hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 3
             message: @"d"];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 4
             message: @"e"];
  
  [self assertString: output
            hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 5
             message: @"f"];
  
  [self assertString: output
            hasValue: nil
        forAttribute: NSStrikethroughStyleAttributeName
             atIndex: 6
             message: @"g"];
}

- (void) testFormattingOverTwoLines
{
  NSAttributedString *input1 = [self constructAttributedStringForString: @"a\x1B["];  
  NSAttributedString *input2 = [self constructAttributedStringForString: @"4mb"];  
  [self.queue processCompleteLine: input1];
  
  NSAttributedString *output = [self.queue processCompleteLine: input2];
   
  [self assertString: output hasValue: @(NSUnderlineStyleSingle)
        forAttribute: NSUnderlineStyleAttributeName
             atIndex: 0
             message: @"b"];
}

- (void) testRetainsPartialCode
{
  @autoreleasepool
  {
    [self assertInput: @"\x1B[" hasOutput: @""];
  }
  [self assertInput: @"m" hasOutput: @""];
}

- (void) testEraseData
{
  [self assertInput: @"a\x1B[1J" hasOutput: @""];
  [self assertInput: @"a\x1B[1Jb" hasOutput: @"b"];
  [self assertInput: @"\x1B[1Jb" hasOutput: @"b"];
  [self assertInput: @"a\x1B[2J" hasOutput: @""];
  [self assertInput: @"a\x1B[2Jb" hasOutput: @"b"];
  [self assertInput: @"\x1B[2Jb" hasOutput: @"b"];
}

- (void) testIgnoresUnhandledButValidCodes
{
  NSString *nonHandledCodes = @"\007ABCDEFGHKSTcfhlnsuz"; // Some of the unhandled codes are vt100, technically.
  
  for (NSUInteger i = 0; i < nonHandledCodes.length; i++)
  {
    unichar code = [nonHandledCodes characterAtIndex: i];
    NSString *testString = [NSString stringWithFormat: @"\x1B[%cm", (char) code];
    [self assertInput: testString
            hasOutput: @"m"
              message: [NSString stringWithCharacters: &code length: 1]];
    
  }
}

#pragma mark - Private methods

- (void) assertFinalCharacter: (unsigned char) finalChar
{
  [self assertInput: [NSString stringWithFormat: @"F\x1B[%coo", finalChar]
          hasOutput: @"Foo"
            message: [NSString stringWithFormat: @"[%X]", finalChar]];
}

- (void) assertString: (NSAttributedString *) string
             hasValue: (id) value
         forAttribute: (NSString *) attribute
              atIndex: (int) characterIndex
              message: (NSString *) message
{
  NSDictionary *attributes = [string attributesAtIndex: characterIndex effectiveRange: NULL];
  
  [self assert: [attributes valueForKey: attribute] equals: value message: message];
}

- (void) assertString: (NSAttributedString *) string
             hasTrait: (NSFontTraitMask) trait
              atIndex: (int) characterIndex
              message: (NSString *) message
{
  NSFont *font = [string attribute: NSFontAttributeName atIndex: characterIndex effectiveRange: NULL];
  
  [self assertTrue: (BOOL) ([[NSFontManager sharedFontManager] traitsOfFont: font] & trait) message: message];
}

- (void) assertString: (NSAttributedString *) string
           hasntTrait: (NSFontTraitMask) trait
              atIndex: (int) characterIndex
              message: (NSString *) message
{
  NSFont *font = [string attribute: NSFontAttributeName atIndex: characterIndex effectiveRange: NULL];
  
  [self assertFalse: (BOOL) ([[NSFontManager sharedFontManager] traitsOfFont: font] & trait) message: message];
}

@end
