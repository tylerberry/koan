//
// MUTerminalProtocolHandler.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUProtocolStack.h"
#import "MUTerminalStateMachine.h"
#import "NSColor+ANSI.h"
#import "NSFont+Traits.h"

@interface MUTerminalProtocolHandler ()

- (void) _setUpInitialTextAttributes;
- (void) _updateTextAttributesFromProfileBackgroundColor;
- (void) _updateTextAttributesFromProfileFont;
- (void) _updateTextAttributesFromProfileTextColor;

#pragma mark - ANSI Select Graphic Rendition handling

- (void) _handleANSISelectGraphicRendition;
- (void) _setBackgroundColor: (NSColor *) color customColorTag: (enum MUCustomColorTags) customColorTag;
- (void) _setBright;
- (void) _setItalic;
- (void) _setForegroundColor: (NSColor *) color customColorTag: (enum MUCustomColorTags) customColorTag;
- (void) _unsetBackgroundColor;
- (void) _unsetBlink;
- (void) _unsetBright;
- (void) _unsetForegroundColor;
- (void) _unsetHiddenText;
- (void) _unsetInverse;
- (void) _unsetItalic;
- (void) _unsetStrikethrough;
- (void) _unsetUnderline;

@end

#pragma mark -

@implementation MUTerminalProtocolHandler
{
  MUProfile *_profile;
  MUMUDConnectionState *_connectionState;
  MUTerminalStateMachine *_terminalStateMachine;

  NSMutableData *_commandBuffer;

  NSMutableDictionary *_textAttributes;
}

@dynamic textAttributes;

+ (id) protocolHandlerWithProfile: (MUProfile *) profile connectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithProfile: profile connectionState: telnetConnectionState];
}

- (id) initWithProfile: (MUProfile *) profile connectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;

  _profile = profile;
  _terminalStateMachine = [MUTerminalStateMachine stateMachine];

  _commandBuffer = [[NSMutableData alloc] init];

  [self _setUpInitialTextAttributes];

  [_profile addObserver: self forKeyPath: @"effectiveBackgroundColor" options: NSKeyValueObservingOptionNew context: NULL];
  [_profile addObserver: self forKeyPath: @"effectiveFont" options: NSKeyValueObservingOptionNew context: NULL];
  [_profile addObserver: self forKeyPath: @"effectiveTextColor" options: NSKeyValueObservingOptionNew context: NULL];

  return self;
}

- (void) dealloc
{
  [_profile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
  [_profile removeObserver: self forKeyPath: @"effectiveFont"];
  [_profile removeObserver: self forKeyPath: @"effectiveTextColor"];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == _profile)
  {
    if ([keyPath isEqualToString: @"effectiveBackgroundColor"])
    {
      [self _updateTextAttributesFromProfileBackgroundColor];
      return;
    }
    if ([keyPath isEqualToString: @"effectiveFont"])
    {
      [self _updateTextAttributesFromProfileFont];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveTextColor"])
    {
      [self _updateTextAttributesFromProfileTextColor];
      return;
    }
  }

  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

- (NSDictionary *) textAttributes
{
  return _textAttributes;
}

#pragma mark - MUTerminalProtocolHandler protocol

- (void) bufferCommandByte: (uint8_t) byte
{
  [_commandBuffer appendBytes: &byte length: 1];
}

- (void) bufferTextByte: (uint8_t) byte
{
  PASS_ON_PARSED_BYTE (byte);
}

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);

  [self.delegate log: message arguments: args];

  va_end (args);
}

- (void) processCommandStringWithType: (enum MUTerminalControlStringTypes) commandStringType
{
  switch (commandStringType)
  {
    case MUTerminalControlStringTypeOperatingSystemCommand:
#ifdef DEBUG_LOG_TERMINAL
      [self log: @"Terminal: OSC %@", _commandBuffer];
#endif
      break;

    case MUTerminalControlStringTypePrivacyMessage:
#ifdef DEBUG_LOG_TERMINAL
      [self log: @"Terminal: PM %@", _commandBuffer];
#endif
      break;

    case MUTerminalControlStringTypeApplicationProgram:
#ifdef DEBUG_LOG_TERMINAL
      [self log: @"Terminal: AP %@", _commandBuffer];
#endif
      break;

  }
  _commandBuffer.data = [NSData data];
}

- (void) processCSIWithFinalByte: (uint8_t) finalByte
{
#ifdef DEBUG_LOG_TERMINAL
  uint8_t bytes[_commandBuffer.length + 1];

  [_commandBuffer getBytes: bytes];
  bytes[_commandBuffer.length] = 0x00;

  [self log: @"Terminal: CSI %s%c [%02u/%02u]", bytes, finalByte, finalByte / 16, finalByte % 16];
#endif

  switch (finalByte)
  {
    case 'm':
      [self _handleANSISelectGraphicRendition];
  }

  _commandBuffer.data = [NSData data];
}

- (void) processPseudoANSIMusic
{
#ifdef DEBUG_LOG_TERMINAL
  [self log: @"Terminal: Pseudo-ANSI Music %@", _commandBuffer];
#endif

  _commandBuffer.data = [NSData data];
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  [_terminalStateMachine parse: byte forProtocolHandler: self];
}

- (void) preprocessByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (byte);
}

- (void) preprocessFooterData: (NSData *) data
{
  PASS_ON_PREPROCESSED_FOOTER_DATA (data);
}

#pragma mark - Private methods

- (void) _setUpInitialTextAttributes
{
  _textAttributes = [[NSMutableDictionary alloc] init];
  _textAttributes[NSFontAttributeName] = _profile.effectiveFont;
  _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveTextColor;
  _textAttributes[MUCustomForegroundColorAttributeName] = @(MUDefaultForegroundColorTag);
  _textAttributes[MUCustomBackgroundColorAttributeName] = @(MUDefaultBackgroundColorTag);
}

- (void) _updateTextAttributesFromProfileBackgroundColor
{
  if (_textAttributes[MUInverseColorsAttributeName]
      && [_textAttributes[MUCustomBackgroundColorAttributeName] intValue] == MUDefaultBackgroundColorTag)
  {
    _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveBackgroundColor;
  }
}

- (void) _updateTextAttributesFromProfileFont
{
  NSFont *newEffectiveFont;

  if (_textAttributes[MUBrightColorAttributeName]
      || ([[NSUserDefaults standardUserDefaults] boolForKey: MUPDisplayBrightAsBold]
          && ([_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightBlackColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightBlueColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightCyanColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightGreenColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightMagentaColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightRedColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightWhiteColorTag
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUANSI256BrightYellowColorTag)))
  {
    newEffectiveFont = [_profile.effectiveFont boldFontWithRespectTo: _profile.effectiveFont];
  }
  else
  {
    newEffectiveFont = _profile.effectiveFont;
  }

  _textAttributes[NSFontAttributeName] = newEffectiveFont;
}

- (void) _updateTextAttributesFromProfileTextColor
{
  if ([_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUDefaultForegroundColorTag)
  {
    if (_textAttributes[MUInverseColorsAttributeName])
      _textAttributes[NSBackgroundColorAttributeName] = _profile.effectiveTextColor;
    else
      _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveTextColor;
  }
}

#pragma mark - ANSI SGR

- (void) _handleANSISelectGraphicRendition
{
  [self.protocolStack flushBufferedData];

  NSString *commandCode = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];
  NSArray *codeComponents = [commandCode componentsSeparatedByString: @";"];

  if (codeComponents.count == 3 && [codeComponents[1] intValue] == 5)
  {
    if ([codeComponents[0] intValue] == MUANSIForeground256)
    {
      int colorCode = [codeComponents[2] intValue];

      if (colorCode >= 0 && colorCode < 16)
      {
        NSColor *targetColor;
        enum MUCustomColorTags customColorTag;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        switch (colorCode)
        {
          case MUANSI256Black:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
            customColorTag = MUANSI256BlackColorTag;
            break;

          case MUANSI256BrightBlack:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
            customColorTag = MUANSI256BrightBlackColorTag;
            break;

          case MUANSI256Red:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
            customColorTag = MUANSI256RedColorTag;
            break;

          case MUANSI256BrightRed:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
            customColorTag = MUANSI256BrightRedColorTag;
            break;

          case MUANSI256Green:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
            customColorTag = MUANSI256GreenColorTag;
            break;

          case MUANSI256BrightGreen:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
            customColorTag = MUANSI256BrightGreenColorTag;
            break;

          case MUANSI256Yellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
            customColorTag = MUANSI256YellowColorTag;
            break;

          case MUANSI256BrightYellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
            customColorTag = MUANSI256BrightYellowColorTag;
            break;

          case MUANSI256Blue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
            customColorTag = MUANSI256BlueColorTag;
            break;

          case MUANSI256BrightBlue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
            customColorTag = MUANSI256BrightBlueColorTag;
            break;

          case MUANSI256Magenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
            customColorTag = MUANSI256MagentaColorTag;
            break;

          case MUANSI256BrightMagenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
            customColorTag = MUANSI256BrightMagentaColorTag;
            break;

          case MUANSI256Cyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
            customColorTag = MUANSI256CyanColorTag;
            break;

          case MUANSI256BrightCyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
            customColorTag = MUANSI256BrightCyanColorTag;
            break;

          case MUANSI256White:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
            customColorTag = MUANSI256WhiteColorTag;
            break;

          case MUANSI256BrightWhite:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
            customColorTag = MUANSI256BrightWhiteColorTag;
            break;
        }

        [self _setForegroundColor: targetColor customColorTag: customColorTag];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        [self _setForegroundColor: [NSColor ANSI256ColorCubeColorForCode: (uint8_t) colorCode]
                   customColorTag: MUANSI256FixedColorTag];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        [self _setForegroundColor: [NSColor ANSI256GrayscaleColorForCode: (uint8_t) colorCode]
                   customColorTag: MUANSI256FixedColorTag];
      }

      return;
    }
    else if ([codeComponents[0] intValue] == MUANSIBackground256)
    {
      int colorCode = [codeComponents[2] intValue];

      if (colorCode >= 0 && colorCode < 16)
      {
        NSColor *targetColor;
        enum MUCustomColorTags customColorTag;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        switch (colorCode)
        {
          case MUANSI256Black:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
            customColorTag = MUANSI256BlackColorTag;
            break;

          case MUANSI256BrightBlack:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
            customColorTag = MUANSI256BrightBlackColorTag;
            break;

          case MUANSI256Red:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
            customColorTag = MUANSI256RedColorTag;
            break;

          case MUANSI256BrightRed:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
            customColorTag = MUANSI256BrightRedColorTag;
            break;

          case MUANSI256Green:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
            customColorTag = MUANSI256GreenColorTag;
            break;

          case MUANSI256BrightGreen:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
            customColorTag = MUANSI256BrightGreenColorTag;
            break;

          case MUANSI256Yellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
            customColorTag = MUANSI256YellowColorTag;
            break;

          case MUANSI256BrightYellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
            customColorTag = MUANSI256BrightYellowColorTag;
            break;

          case MUANSI256Blue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
            customColorTag = MUANSI256BlueColorTag;
            break;

          case MUANSI256BrightBlue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
            customColorTag = MUANSI256BrightBlueColorTag;
            break;

          case MUANSI256Magenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
            customColorTag = MUANSI256MagentaColorTag;
            break;

          case MUANSI256BrightMagenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
            customColorTag = MUANSI256BrightMagentaColorTag;
            break;

          case MUANSI256Cyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
            customColorTag = MUANSI256CyanColorTag;
            break;

          case MUANSI256BrightCyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
            customColorTag = MUANSI256BrightCyanColorTag;
            break;

          case MUANSI256White:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
            customColorTag = MUANSI256WhiteColorTag;
            break;

          case MUANSI256BrightWhite:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
            customColorTag = MUANSI256BrightWhiteColorTag;
            break;
        }

        [self _setBackgroundColor: targetColor customColorTag: customColorTag];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        [self _setBackgroundColor: [NSColor ANSI256ColorCubeColorForCode: (uint8_t) colorCode]
                   customColorTag: MUANSI256FixedColorTag];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        [self _setBackgroundColor: [NSColor ANSI256GrayscaleColorForCode: (uint8_t) colorCode]
                   customColorTag: MUANSI256FixedColorTag];
      }

      return;
    }
  }

  for (NSString *code in codeComponents)
  {
    switch (code.intValue)
    {
      case MUANSIReset:
        [self _unsetInverse];
        [self _unsetHiddenText];
        [self _unsetBright];
        [self _unsetItalic];
        [self _unsetForegroundColor];
        [self _unsetBackgroundColor];
        [self _unsetUnderline];
        [self _unsetStrikethrough];
        [self _unsetBlink];
        break;

      case MUANSIBoldOn:
        [self _setBright];
        break;

      case MUANSIItalicsOn:
        [self _setItalic];
        break;

      case MUANSIUnderlineOn:
        _textAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleSingle);
        break;

      case MUANSISlowBlinkOn:
        _textAttributes[MUBlinkingTextAttributeName] = @(MUSlowBlink);
        break;

      case MUANSIRapidBlinkOn:
        _textAttributes[MUBlinkingTextAttributeName] = @(MURapidBlink);
        break;

      case MUANSIInverseOn:
      {
        if ([_textAttributes[MUInverseColorsAttributeName] boolValue] == NO)
        {
          _textAttributes[MUInverseColorsAttributeName] = @YES;

          NSColor *savedForegroundColor = _textAttributes[NSForegroundColorAttributeName];

          if (_textAttributes[NSBackgroundColorAttributeName])
            _textAttributes[NSForegroundColorAttributeName] = _textAttributes[NSBackgroundColorAttributeName];
          else
            _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveBackgroundColor;
          
          _textAttributes[NSBackgroundColorAttributeName ] = savedForegroundColor;
        }

        break;
      }

      case MUANSIHiddenTextOn:
        _textAttributes[MUHiddenTextAttributeName] = @YES;
        break;

      case MUANSIStrikethroughOn:
        _textAttributes[MUHiddenTextAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleSingle);
        break;

      case MUANSIDoubleUnderlineOn:
        _textAttributes[MUHiddenTextAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleDouble);
        break;

      case MUANSIBoldOff:
        [self _unsetBright];
        break;

      case MUANSIItalicsOff:
        [self _unsetItalic];

      case MUANSIUnderlineOff:
        [self _unsetUnderline];
        break;

      case MUANSIBlinkOff:
        [self _unsetBlink];
        break;

      case MUANSIInverseOff:
        [self _unsetInverse];
        break;

      case MUANSIHiddenTextOff:
        [self _unsetHiddenText];
        break;

      case MUANSIStrikethroughOff:
        [self _unsetStrikethrough];
        break;

      case MUANSIForegroundBlack:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];

        [self _setForegroundColor: color customColorTag: MUANSIBlackColorTag];
        break;
      }

      case MUANSIForegroundRed:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];

        [self _setForegroundColor: color customColorTag: MUANSIRedColorTag];
        break;
      }

      case MUANSIForegroundGreen:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];

        [self _setForegroundColor: color customColorTag: MUANSIGreenColorTag];
        break;
      }

      case MUANSIForegroundYellow:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];

        [self _setForegroundColor: color customColorTag: MUANSIYellowColorTag];
        break;
      }

      case MUANSIForegroundBlue:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];

        [self _setForegroundColor: color customColorTag: MUANSIBlueColorTag];
        break;
      }

      case MUANSIForegroundMagenta:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];

        [self _setForegroundColor: color customColorTag: MUANSIMagentaColorTag];
        break;
      }

      case MUANSIForegroundCyan:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];

        [self _setForegroundColor: color customColorTag: MUANSICyanColorTag];
        break;
      }

      case MUANSIForegroundWhite:
      {
        NSColor *color;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if (_textAttributes[MUBrightColorAttributeName])
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
        else
          color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];

        [self _setForegroundColor: color customColorTag: MUANSIWhiteColorTag];
        break;
      }

      case MUANSIForegroundDefault:
        [self _unsetForegroundColor];
        break;

      case MUANSIBackgroundBlack:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIBlackColorTag];
        break;
      }

      case MUANSIBackgroundRed:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIRedColorTag];
        break;
      }

      case MUANSIBackgroundGreen:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIGreenColorTag];
        break;
      }

      case MUANSIBackgroundYellow:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIYellowColorTag];
        break;
      }

      case MUANSIBackgroundBlue:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIBlueColorTag];
        break;
      }

      case MUANSIBackgroundMagenta:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIMagentaColorTag];
        break;
      }

      case MUANSIBackgroundCyan:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];

        [self _setBackgroundColor: color customColorTag: MUANSICyanColorTag];
        break;
      }

      case MUANSIBackgroundWhite:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];

        [self _setBackgroundColor: color customColorTag: MUANSIWhiteColorTag];
        break;
      }

      case MUANSIBackgroundDefault:
        [self _unsetBackgroundColor];
        break;

      default:
        [self log: @"Terminal: Unhandled ANSI SGR code: %@", code];
        break;
    }
  }
}

- (void) _setBackgroundColor: (NSColor *) color customColorTag: (enum MUCustomColorTags) customColorTag
{
  _textAttributes[MUCustomBackgroundColorAttributeName] = @(customColorTag);

  if (_textAttributes[MUInverseColorsAttributeName])
    _textAttributes[NSForegroundColorAttributeName] = color;
  else
    _textAttributes[NSBackgroundColorAttributeName] = color;
}

- (void) _setBright
{
  _textAttributes[MUBrightColorAttributeName] = @YES;


  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ([defaults boolForKey: MUPDisplayBrightAsBold])
  {
    _textAttributes[NSFontAttributeName] = [_textAttributes[NSFontAttributeName] boldFontWithRespectTo: _profile.effectiveFont];
  }

  NSColor *color;

  switch ([_textAttributes[MUCustomForegroundColorAttributeName] intValue])
  {
    case MUANSIBlackColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
      break;

    case MUANSIRedColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
      break;

    case MUANSIGreenColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
      break;

    case MUANSIYellowColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
      break;

    case MUANSIBlueColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
      break;

    case MUANSIMagentaColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
      break;

    case MUANSICyanColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
      break;

    case MUANSIWhiteColorTag:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
      break;

    default:
      return;
  }

  if (_textAttributes[MUInverseColorsAttributeName])
    _textAttributes[NSBackgroundColorAttributeName] = color;
  else
    _textAttributes[NSForegroundColorAttributeName] = color;
}

- (void) _setForegroundColor: (NSColor *) color customColorTag: (enum MUCustomColorTags) customColorTag
{
  _textAttributes[MUCustomForegroundColorAttributeName] = @(customColorTag);

  if (_textAttributes[MUInverseColorsAttributeName])
    _textAttributes[NSBackgroundColorAttributeName] = color;
  else
    _textAttributes[NSForegroundColorAttributeName] = color;
}

- (void) _setItalic
{
  _textAttributes[MUItalicFontAttributeName] = @YES;
  _textAttributes[NSFontAttributeName] = [_textAttributes[NSFontAttributeName] italicFontWithRespectTo: _profile.effectiveFont];
}

- (void) _unsetBackgroundColor
{
  _textAttributes[MUCustomBackgroundColorAttributeName] = @(MUDefaultBackgroundColorTag);

  if (_textAttributes[MUInverseColorsAttributeName])
  {
    _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveBackgroundColor;
  }
  else
  {
    [_textAttributes removeObjectForKey: NSBackgroundColorAttributeName];
  }
}

- (void) _unsetBlink
{
  [_textAttributes removeObjectForKey: MUBlinkingTextAttributeName];
}

- (void) _unsetBright
{
  if (_textAttributes[MUBrightColorAttributeName])
  {
    [_textAttributes removeObjectForKey: MUBrightColorAttributeName];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey: MUPDisplayBrightAsBold])
    {
      _textAttributes[NSFontAttributeName] = [_textAttributes[NSFontAttributeName] unboldFontWithRespectTo: _profile.effectiveFont];
    }

    NSColor *color = nil;

    switch ([_textAttributes[MUCustomForegroundColorAttributeName] intValue])
    {
      case MUANSIBlackColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
        break;

      case MUANSIRedColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
        break;

      case MUANSIGreenColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
        break;

      case MUANSIYellowColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
        break;

      case MUANSIBlueColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
        break;

      case MUANSIMagentaColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
        break;

      case MUANSICyanColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
        break;

      case MUANSIWhiteColorTag:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
        break;

      default:
        return;
    }

    if (_textAttributes[MUInverseColorsAttributeName])
      _textAttributes[NSBackgroundColorAttributeName] = color;
    else
      _textAttributes[NSForegroundColorAttributeName] = color;
  }
}

- (void) _unsetForegroundColor
{
  _textAttributes[MUCustomForegroundColorAttributeName] = @(MUDefaultForegroundColorTag);

  if (_textAttributes[MUInverseColorsAttributeName])
    _textAttributes[NSBackgroundColorAttributeName] = _profile.effectiveTextColor;
  else
    _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveTextColor;
}

- (void) _unsetHiddenText
{
  [_textAttributes removeObjectForKey: MUHiddenTextAttributeName];
}

- (void) _unsetInverse
{
  if (_textAttributes[MUInverseColorsAttributeName])
  {
    [_textAttributes removeObjectForKey: MUInverseColorsAttributeName];

    NSColor *savedForegroundColor = _textAttributes[NSForegroundColorAttributeName];

    _textAttributes[NSForegroundColorAttributeName] = _textAttributes[NSBackgroundColorAttributeName];

    if ([_textAttributes[MUCustomBackgroundColorAttributeName] intValue] == MUDefaultBackgroundColorTag)
      [_textAttributes removeObjectForKey: NSBackgroundColorAttributeName];
    else
      _textAttributes[NSBackgroundColorAttributeName] = savedForegroundColor;
  }
}

- (void) _unsetItalic
{
  if (_textAttributes[MUItalicFontAttributeName])
  {
    [_textAttributes removeObjectForKey: MUItalicFontAttributeName];

    NSFont *currentFont = _textAttributes[NSFontAttributeName];
    _textAttributes[NSFontAttributeName] = [currentFont unitalicFontWithRespectTo: _profile.effectiveFont];
  }
}

- (void) _unsetStrikethrough
{
  [_textAttributes removeObjectForKey: NSStrikethroughStyleAttributeName];
}

- (void) _unsetUnderline
{
  [_textAttributes removeObjectForKey: NSUnderlineStyleAttributeName];
}

@end
