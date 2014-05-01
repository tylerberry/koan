//
// MUTerminalProtocolHandlerTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTerminalProtocolHandlerTests.h"

#import "MUMUDConnectionState.h"
#import "MUProfile.h"
#import "NSColor+ANSI.h"
#import "NSFont+Traits.h"

#define TESTING_BACKGROUND_COLOR [NSColor redColor]
#define TESTING_LINK_COLOR [NSColor yellowColor]
#define TESTING_SYSTEM_TEXT_COLOR [NSColor darkGrayColor]
#define TESTING_TEXT_COLOR [NSColor purpleColor]

#define COLOR(c) [NSUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] dataForKey:(c)]]

@interface MUProfile (TestingANSI)

+ (id) _profileForTestingANSI;

@end

#pragma mark -

@implementation MUProfile (TestingANSI)

+ (id) _profileForTestingANSI
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

@interface MUTerminalProtocolHandlerTests ()

- (void) _assertFinalCharacter: (unsigned char) finalChar;
- (void) _assertInput: (NSString *) inputString hasOutput: (NSString *) _outputString;
- (void) _assertInput: (NSString *) inputString hasOutput: (NSString *) _outputString message: (NSString *) message;
- (void) _assertString: (NSAttributedString *) string
              hasValue: (id) value
          forAttribute: (NSString *) attribute
               atIndex: (int) characterIndex
               message: (NSString *) message;
- (void) _assertString: (NSAttributedString *) string
              hasTrait: (NSFontTraitMask) trait
               atIndex: (int) characterIndex
               message: (NSString *) message;
- (void) _assertString: (NSAttributedString *) string
            hasntTrait: (NSFontTraitMask) trait
               atIndex: (int) characterIndex
               message: (NSString *) message;
- (void) _clearOutputBuffer;
- (void) _parseString: (NSString *) string;

@end

#pragma mark -

@implementation MUTerminalProtocolHandlerTests
{
  MUProtocolStack *_protocolStack;
  MUTerminalProtocolHandler *_terminalProtocolHandler;
  MUProfile *_profile;
  NSMutableAttributedString *_outputBuffer;
}

- (void) setUp
{
  [super setUp];

  MUMUDConnectionState *connectionState = [[MUMUDConnectionState alloc] initWithCodebaseAnalyzerDelegate: nil];
  connectionState.allowCodePage437Substitution = NO;

  _protocolStack = [[MUProtocolStack alloc] initWithConnectionState: connectionState];
  _protocolStack.delegate = self;

  _profile = [MUProfile _profileForTestingANSI];

  _terminalProtocolHandler = [[MUTerminalProtocolHandler alloc] initWithProfile: _profile
                                                                connectionState: connectionState];
  _terminalProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: _terminalProtocolHandler];

  _outputBuffer = [[NSMutableAttributedString alloc] init];
}

- (void) tearDown
{
  _protocolStack = nil;
  _outputBuffer = nil;

  [super tearDown];
}

- (void) testNoCode
{
  [self _assertInput: @"Foo"
           hasOutput: @"Foo"];
}

- (void) testSingleCharacter
{
  [self _assertInput: @"Q"
           hasOutput: @"Q"];
}

- (void) testBasicCode
{
  [self _assertInput: @"F\x1B[moo"
           hasOutput: @"Foo"
             message: @"One"];
  [self _assertInput: @"F\x1B[3moo"
           hasOutput: @"Foo"
             message: @"Two"];
  [self _assertInput: @"F\x1B[36moo"
           hasOutput: @"Foo"
             message: @"Three"];
}

- (void) testTwoCodes
{
  [self _assertInput: @"F\x1B[36moa\x1B[3mob"
           hasOutput: @"Foaob"];
}

- (void) testCompoundCode
{
  [self _assertInput: @"F\x1B[0;1;3;32;45moo"
           hasOutput: @"Foo"];
}

- (void) testNewLine
{
  [self _assertInput: @"Foo\n"
           hasOutput: @"Foo\n"];
}

- (void) testOnlyNewLine
{
  [self _assertInput: @"\n"
           hasOutput: @"\n"];
}

- (void) testCodeAtEndOfLine
{
  [self _assertInput: @"Foo\x1B[36m\n"
           hasOutput: @"Foo\n"];
}

- (void) testCodeAtBeginningOfString
{
  [self _assertInput: @"\x1B[36mFoo"
           hasOutput: @"Foo"];
}

- (void) testCodeAtEndOfString
{
  [self _assertInput: @"Foo\x1B[36m"
           hasOutput: @"Foo"];
}

- (void) testEmptyString
{
  [self _assertInput: @""
           hasOutput: @""];
}

- (void) testOnlyCode
{
  [self _assertInput: @"\x1B[36m"
           hasOutput: @""];
}

- (void) testCodeSplitOverTwoStrings
{
  [self _assertInput: @"\x1B[" hasOutput: @""];
  [self _assertInput: @"36m" hasOutput: @""];
}

- (void) testCodeWithJustTerminatorInSecondString
{
  [self _assertInput: @"\x1B[36" hasOutput: @""];
  [self _assertInput: @"m" hasOutput: @""];
}

- (void) testLongString
{
  NSString *longString =
  @"        #@@N         (@@)     (@@@)        J@@@@F      @@@@@@@L";
  [self _assertInput: longString
           hasOutput: longString];
}

- (void) testOnlyWhitespaceBeforeCodeAndNothingAfterIt
{
  [self _assertInput: @" \x1B[1m"
           hasOutput: @" "];
}

- (void) testForegroundColor
{
  NSString *input = @"a\x1B[36mbc\x1B[35md\x1B[39me";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 3
              message: @"d"];
  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 4
              message: @"e"];
}

- (void) testStandardForegroundColors
{
  NSString *input = @"\x1B[30ma\x1B[31mb\x1B[32mc\x1B[33md\x1B[34me\x1B[35mf\x1B[36mg\x1B[37mh";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlackColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIRedColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIGreenColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIYellowColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 3
              message: @"d"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlueColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 4
              message: @"e"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 5
              message: @"f"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 6
              message: @"g"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIWhiteColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 7
              message: @"h"];
}

- (void) testXTerm256ForegroundColor
{
  for (unsigned i = 0; i < 16; i++)
  {
    NSString *input = [NSString stringWithFormat: @"\x1B[38;5;%dm%d", i, i];
    [self _parseString: input];

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

    [self _assertString: _outputBuffer
               hasValue: targetColor
           forAttribute: NSForegroundColorAttributeName
                atIndex: 0
                message: [NSString stringWithFormat: @"%d", i]];

    [self _clearOutputBuffer];
  }

  for (uint16_t i = 16; i < 232; i++)
  {
    NSString *input = [NSString stringWithFormat: @"\x1B[38;5;%dm%d", i, i];
    [self _parseString: input];

    NSColor *expectedColor = [NSColor ANSI256ColorCubeColorForCode: (uint8_t) i];

    [self _assertString: _outputBuffer
               hasValue: expectedColor
           forAttribute: NSForegroundColorAttributeName
                atIndex: 0
                message: [NSString stringWithFormat: @"%d", i]];

    [self _clearOutputBuffer];
  }

  for (uint16_t i = 232; i < 256; i++)
  {
    NSString *input = [NSString stringWithFormat: @"\x1B[38;5;%dm%d", i, i];
    [self _parseString: input];

    NSColor *expectedColor = [NSColor ANSI256GrayscaleColorForCode: (uint8_t) i];

    [self _assertString: _outputBuffer
               hasValue: expectedColor
           forAttribute: NSForegroundColorAttributeName
                atIndex: 0
                message: [NSString stringWithFormat: @"%d", i]];

    [self _clearOutputBuffer];
  }
}

- (void) testBackgroundColor
{
  NSString *input = @"a\x1B[46mbc\x1B[45md\x1B[49me";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 0
              message: @"a"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 2
              message: @"c"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 3
              message: @"d"];
  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 4
              message: @"e"];
}

- (void) testStandardBackgroundColors
{
  NSString *input = @"\x1B[40ma\x1B[41mb\x1B[42mc\x1B[43md\x1B[44me\x1B[45mf\x1B[46mg\x1B[47mh";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlackColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 0
              message: @"a"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIRedColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIGreenColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 2
              message: @"c"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIYellowColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 3
              message: @"d"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlueColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 4
              message: @"e"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 5
              message: @"f"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 6
              message: @"g"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIWhiteColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 7
              message: @"h"];
}

- (void) testXTerm256BackgroundColor
{
  for (unsigned i = 0; i < 16; i++)
  {
    NSString *input = [NSString stringWithFormat: @"\x1B[48;5;%dm%d", i, i];
    [self _parseString: input];

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

    [self _assertString: _outputBuffer
               hasValue: targetColor
           forAttribute: NSBackgroundColorAttributeName
                atIndex: 0
                message: [NSString stringWithFormat: @"%d", i]];

    [self _clearOutputBuffer];
  }

  for (uint16_t i = 16; i < 232; i++)
  {
    NSString *input = [NSString stringWithFormat: @"\x1B[48;5;%dm%d", i, i];
    [self _parseString: input];

    NSColor *expectedColor = [NSColor ANSI256ColorCubeColorForCode: (uint8_t) i];

    [self _assertString: _outputBuffer
               hasValue: expectedColor
           forAttribute: NSBackgroundColorAttributeName
                atIndex: 0
                message: [NSString stringWithFormat: @"%d", i]];

    [self _clearOutputBuffer];
  }

  for (uint16_t i = 232; i < 256; i++)
  {
    NSString *input = [NSString stringWithFormat: @"\x1B[48;5;%dm%d", i, i];
    [self _parseString: input];

    NSColor *expectedColor = [NSColor ANSI256GrayscaleColorForCode: (uint8_t) i];

    [self _assertString: _outputBuffer
               hasValue: expectedColor
           forAttribute: NSBackgroundColorAttributeName
                atIndex: 0
                message: [NSString stringWithFormat: @"%d", i]];

    [self _clearOutputBuffer];
  }
}

- (void) testForegroundAndBackgroundColorAsCompoundCode
{
  NSString *input = @"a\x1B[36;46mbc\x1B[45;35md\x1B[39;49me";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 0
              message: @"a background"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b background"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 2
              message: @"c background"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 3
              message: @"d foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 3
              message: @"d background"];
  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 4
              message: @"e foreground"];
  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 4
              message: @"e background"];
}

- (void) testResetDisplayMode
{
  NSString *input = @"a\x1B[36m\x1B[46mb\x1B[0mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b background"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 2
              message: @"c background"];
  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testCompoundSetThenResetDisplayMode
{
  NSString *input = @"a\x1B[36;46mb\x1B[0mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b background"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName atIndex: 2
              message: @"c background"];
  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testShortFormOfResetDisplayMode
{
  NSString *input = @"a\x1B[36m\x1B[46mb\x1B[mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b background"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 2
              message: @"c background"];
  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testMidCodeResetDisplayMode
{
  NSString *input = @"a\x1B[36;46;0mb";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSBackgroundColorAttributeName
              atIndex: 1
              message: @"b background"];
  [self _assertString: _outputBuffer
             hasValue: TESTING_TEXT_COLOR
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
}

- (void) testPersistColorsBetweenLines
{
  [self _parseString: @"a\x1B[36mb"];
  [self _parseString: @"c"];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c"];
}

- (void) testBold
{
  NSString *input = @"a\x1B[1mb\x1B[22mc\x1B[1md\x1B[0me\x1B[1mf\x1B[mg";
  [self _parseString: input];

  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 0 message: @"a"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUBrightColorAttributeName atIndex: 1 message: @"b"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 2 message: @"c"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUBrightColorAttributeName atIndex: 3 message: @"d"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 4 message: @"e"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUBrightColorAttributeName atIndex: 5 message: @"f"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 6 message: @"g"];
}

- (void) testBoldBrightBlackColorChanges
{
  NSString *input = @"\x1B[30ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlackColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightBlackColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlackColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightRedColorChanges
{
  NSString *input = @"\x1B[31ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIRedColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightRedColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIRedColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightGreenColorChanges
{
  NSString *input = @"\x1B[32ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIGreenColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightGreenColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIGreenColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightYellowColorChanges
{
  NSString *input = @"\x1B[33ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIYellowColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightYellowColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIYellowColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightBlueColorChanges
{
  NSString *input = @"\x1B[34ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlueColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightBlueColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBlueColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightMagentaColorChanges
{
  NSString *input = @"\x1B[35ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightMagentaColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIMagentaColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightCyanColorChanges
{
  NSString *input = @"\x1B[36ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightCyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSICyanColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldBrightWhiteColorChanges
{
  NSString *input = @"\x1B[37ma\x1B[1mb\x1B[22mc";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIWhiteColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 0
              message: @"a foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIBrightWhiteColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 1
              message: @"b foreground"];
  [self _assertString: _outputBuffer
             hasValue: COLOR (MUPANSIWhiteColor)
         forAttribute: NSForegroundColorAttributeName
              atIndex: 2
              message: @"c foreground"];
}

- (void) testBoldWithBoldAlreadyOn
{
  NSString *input = @"a\x1B[1mb\x1B[22mc\x1B[1md\x1B[0me\x1B[1mf\x1B[mg";

  _profile.font = [[NSFontManager sharedFontManager] convertFont: _profile.font toHaveTrait: NSBoldFontMask];

  [self _parseString: input];

  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 0 message: @"a"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUBrightColorAttributeName atIndex: 1 message: @"b"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 2 message: @"c"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUBrightColorAttributeName atIndex: 3 message: @"d"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 4 message: @"e"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUBrightColorAttributeName atIndex: 5 message: @"f"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 6 message: @"g"];

  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUBrightColorAttributeName atIndex: 0 message: @"a2"];
}

- (void) testItalic
{
  NSString *input = @"a\x1B[3mb\x1B[23mc\x1B[3md\x1B[0me\x1B[3mf\x1B[mg";
  [self _parseString: input];

  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 0 message: @"a"];
  [self _assertString: _outputBuffer hasntTrait: NSItalicFontMask atIndex: 0 message: @"a trait"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUItalicFontAttributeName atIndex: 1 message: @"b"];
  [self _assertString: _outputBuffer hasTrait: NSItalicFontMask atIndex: 1 message: @"b trait"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 2 message: @"c"];
  [self _assertString: _outputBuffer hasntTrait: NSItalicFontMask atIndex: 2 message: @"c trait"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUItalicFontAttributeName atIndex: 3 message: @"d"];
  [self _assertString: _outputBuffer hasTrait: NSItalicFontMask atIndex: 3 message: @"d trait"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 4 message: @"e"];
  [self _assertString: _outputBuffer hasntTrait: NSItalicFontMask atIndex: 4 message: @"e trait"];
  [self _assertString: _outputBuffer hasValue: @YES forAttribute: MUItalicFontAttributeName atIndex: 5 message: @"f"];
  [self _assertString: _outputBuffer hasTrait: NSItalicFontMask atIndex: 5 message: @"f trait"];
  [self _assertString: _outputBuffer hasValue: nil forAttribute: MUItalicFontAttributeName atIndex: 6 message: @"g"];
  [self _assertString: _outputBuffer hasntTrait: NSItalicFontMask atIndex: 6 message: @"g trait"];
}

- (void) testUnderline
{
  NSString *input = @"a\x1B[4mb\x1B[24mc\x1B[4md\x1B[0me\x1B[4mf\x1B[mg";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 0
              message: @"a"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 1
              message: @"b"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 2
              message: @"c"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 3
              message: @"d"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 4
              message: @"e"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 5
              message: @"f"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 6
              message: @"g"];
}

- (void) testDoubleUnderline
{
  NSString *input = @"a\x1B[21mb\x1B[24mc\x1B[21md\x1B[0me\x1B[21mf\x1B[mg";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 0
              message: @"a"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleDouble)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 1
              message: @"b"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 2
              message: @"c"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleDouble)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 3
              message: @"d"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 4
              message: @"e"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleDouble)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 5
              message: @"f"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 6
              message: @"g"];
}

- (void) testStrikethrough
{
  NSString *input = @"a\x1B[9mb\x1B[29mc\x1B[9md\x1B[0me\x1B[9mf\x1B[mg";
  [self _parseString: input];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 0
              message: @"a"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 1
              message: @"b"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 2
              message: @"c"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 3
              message: @"d"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 4
              message: @"e"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 5
              message: @"f"];

  [self _assertString: _outputBuffer
             hasValue: nil
         forAttribute: NSStrikethroughStyleAttributeName
              atIndex: 6
              message: @"g"];
}

- (void) testFormattingOverTwoLines
{
  [self _parseString: @"a\x1B["];
  [self _parseString: @"4mb"];

  [self _assertString: _outputBuffer
             hasValue: @(NSUnderlineStyleSingle)
         forAttribute: NSUnderlineStyleAttributeName
              atIndex: 1
              message: @"b"];
}

- (void) testRetainsPartialCode
{
  @autoreleasepool
  {
    [self _assertInput: @"\x1B[" hasOutput: @""];
  }
  [self _assertInput: @"m" hasOutput: @""];
}

#if 0
// Disabled for now.
- (void) testEraseData
{
  [self _assertInput: @"a\x1B[1J" hasOutput: @""];
  [self _assertInput: @"a\x1B[1Jb" hasOutput: @"b"];
  [self _assertInput: @"\x1B[1Jb" hasOutput: @"b"];
  [self _assertInput: @"a\x1B[2J" hasOutput: @""];
  [self _assertInput: @"a\x1B[2Jb" hasOutput: @"b"];
  [self _assertInput: @"\x1B[2Jb" hasOutput: @"b"];
}
#endif

- (void) testIgnoresUnhandledButValidCodes
{
  NSString *nonHandledCodes = @"ABCDEFGHJKSTcfhlnsuz"; // Some of the unhandled codes are vt100, technically.

  for (NSUInteger i = 0; i < nonHandledCodes.length; i++)
  {
    unichar code = [nonHandledCodes characterAtIndex: i];
    NSString *testString = [NSString stringWithFormat: @"\x1B[%cm", (char) code];
    [self _assertInput: testString
             hasOutput: @"m"
               message: [NSString stringWithCharacters: &code length: 1]];

  }
}

#pragma mark - MUProtocolStackDelegate protocol

- (void) appendStringToLineBuffer: (NSString *) string
{
  if (!string || string.length == 0)
    return;

  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: string
                                                                         attributes: _terminalProtocolHandler.textAttributes];

  [_outputBuffer appendAttributedString: attributedString];
}

- (void) displayBufferedStringAsPrompt
{
  return;
}

- (void) displayBufferedStringAsText
{
  return;
}

- (void) maybeDisplayBufferedStringAsPrompt
{
  return;
}

- (void) log: (NSString *) message arguments: (va_list) args
{
  return;
}

- (void) writeDataToSocket: (NSData *) preprocessedData
{
  return;
}

#pragma mark - Private methods

- (void) _assertFinalCharacter: (unsigned char) finalChar
{
  [self _assertInput: [NSString stringWithFormat: @"F\x1B[%coo", finalChar]
           hasOutput: @"Foo"
             message: [NSString stringWithFormat: @"[%X]", finalChar]];
}

- (void) _assertInput: (NSString *) inputString hasOutput: (NSString *) _outputString
{
  [self _assertInput: inputString hasOutput: _outputString message: nil];
}

- (void) _assertInput: (NSString *) inputString hasOutput: (NSString *) _outputString message: (NSString *) message
{
  [self _parseString: inputString];

  [self assert: _outputBuffer.string equals: _outputString message: message];

  [self _clearOutputBuffer];
}

- (void) _assertString: (NSAttributedString *) string
              hasValue: (id) value
          forAttribute: (NSString *) attribute
               atIndex: (int) characterIndex
               message: (NSString *) message
{
  NSDictionary *attributes = [string attributesAtIndex: characterIndex effectiveRange: NULL];

  [self assert: [attributes valueForKey: attribute] equals: value message: message];
}

- (void) _assertString: (NSAttributedString *) string
              hasTrait: (NSFontTraitMask) trait
               atIndex: (int) characterIndex
               message: (NSString *) message
{
  NSFont *font = [string attribute: NSFontAttributeName atIndex: characterIndex effectiveRange: NULL];
  
  [self assertTrue: (BOOL) ([[NSFontManager sharedFontManager] traitsOfFont: font] & trait) message: message];
}

- (void) _assertString: (NSAttributedString *) string
            hasntTrait: (NSFontTraitMask) trait
               atIndex: (int) characterIndex
               message: (NSString *) message
{
  NSFont *font = [string attribute: NSFontAttributeName atIndex: characterIndex effectiveRange: NULL];
  
  [self assertFalse: (BOOL) ([[NSFontManager sharedFontManager] traitsOfFont: font] & trait) message: message];
}

- (void) _clearOutputBuffer
{
  [_outputBuffer deleteCharactersInRange: NSMakeRange (0, _outputBuffer.length)];
}

- (void) _parseString: (NSString *) string
{
  [_protocolStack parseInputData: [string dataUsingEncoding: NSASCIIStringEncoding]];
  [_protocolStack flushBufferedData];
}

@end
