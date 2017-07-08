//
// MUTerminalProtocolHandler.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUApplicationController.h"
#import "MUProtocolStack.h"
#import "MUTerminalStateMachine.h"
#import "NSColor+ANSI.h"
#import "NSFont+Traits.h"

@interface MUTerminalProtocolHandler ()

- (void) _setUpInitialTextAttributes;
- (void) _updateColorsForANSIColor: (MUAbstractANSIColor) color;
- (void) _updateDisplayBrightAsBold;
- (void) _updateTextAttributesFromProfileBackgroundColor;
- (void) _updateTextAttributesFromProfileFont;
- (void) _updateTextAttributesFromProfileTextColor;

#pragma mark - ANSI Select Graphic Rendition handling

- (void) _handleANSICursorRight;
- (void) _handleANSISelectGraphicRendition;
- (void) _setBackgroundColor: (NSColor *) color colorTag: (MUColorTag) colorTag;
- (void) _setBright;
- (void) _setItalic;
- (void) _setForegroundColor: (NSColor *) color colorTag: (MUColorTag) colorTag;
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

  BOOL _receivedCarriageReturn;
}

@dynamic textAttributes;

+ (instancetype) protocolHandlerWithProfile: (MUProfile *) profile
                            connectionState: (MUMUDConnectionState *) connectionState
{
  return [[self alloc] initWithProfile: profile connectionState: connectionState];
}

- (instancetype) initWithProfile: (MUProfile *) profile
                 connectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;

  _profile = profile;
  _connectionState = connectionState;
  _terminalStateMachine = [MUTerminalStateMachine stateMachineWithConnectionState: connectionState];

  _commandBuffer = [[NSMutableData alloc] init];
  _receivedCarriageReturn = NO;

  [self _setUpInitialTextAttributes];

  [_profile addObserver: self forKeyPath: @"effectiveBackgroundColor" options: NSKeyValueObservingOptionNew context: NULL];
  [_profile addObserver: self forKeyPath: @"effectiveFont" options: NSKeyValueObservingOptionNew context: NULL];
  [_profile addObserver: self forKeyPath: @"effectiveTextColor" options: NSKeyValueObservingOptionNew context: NULL];

  NSUserDefaultsController *sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBlackColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIRedColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIGreenColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIYellowColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBlueColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIMagentaColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSICyanColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIWhiteColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightBlackColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightRedColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightGreenColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightYellowColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightBlueColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightMagentaColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightCyanColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightWhiteColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForDisplayBrightAsBold]
                                options: NSKeyValueObservingOptionNew
                                context: nil];

  return self;
}

- (void) dealloc
{
  [_profile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
  [_profile removeObserver: self forKeyPath: @"effectiveFont"];
  [_profile removeObserver: self forKeyPath: @"effectiveTextColor"];

  NSUserDefaultsController *sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];

  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBlackColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIRedColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIGreenColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIYellowColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBlueColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIMagentaColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSICyanColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIWhiteColor]];

  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightBlackColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightRedColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightGreenColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightYellowColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightBlueColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightMagentaColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightCyanColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightWhiteColor]];

  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForDisplayBrightAsBold]];
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
  else if (object == [NSUserDefaultsController sharedUserDefaultsController])
  {
    if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBlackColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBlack];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIRedColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorRed];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIGreenColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorGreen];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIYellowColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorYellow];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBlueColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBlue];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIMagentaColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorMagenta];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSICyanColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorCyan];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIWhiteColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorWhite];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightBlackColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightBlack];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightRedColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightRed];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightGreenColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightGreen];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightYellowColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightYellow];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightBlueColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightBlue];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightMagentaColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightMagenta];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightCyanColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightCyan];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightWhiteColor]])
    {
      [self _updateColorsForANSIColor: MUANSIColorBrightWhite];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForDisplayBrightAsBold]])
    {
      [self _updateDisplayBrightAsBold];
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

- (void) handleBackspace
{
  [self.protocolStack moveCursorBackOneCharacter];
}

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);

  [self.delegate log: message arguments: args];

  va_end (args);
}

- (void) processCommandStringWithType: (MUTerminalControlStringType) commandStringType
{
  switch (commandStringType)
  {
    case MUTerminalControlStringTypeOperatingSystemCommand:
    {
      NSString *commandString = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];
      [self log: @"Terminal: Unhandled OSC %@.", commandString];
      break;
    }

    case MUTerminalControlStringTypePrivacyMessage:
    {
      NSString *commandString = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];
      [self log: @"Terminal: Unhandled PM %@.", commandString];
      break;
    }

    case MUTerminalControlStringTypeApplicationProgram:
    {
      NSString *commandString = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];
      [self log: @"Terminal: Unhandled AP %@.", commandString];
      break;
    }
  }

  [_commandBuffer replaceBytesInRange: NSMakeRange (0, _commandBuffer.length) withBytes: NULL length: 0];
}

- (void) processCSIWithFinalByte: (uint8_t) finalByte
{
  switch (finalByte)
  {
    case MUTerminalCSICursorRight:
      [self _handleANSICursorRight];
      break;

    case MUTerminalCSISelectGraphicRendition:
      [self _handleANSISelectGraphicRendition];
      break;

    default:
    {
      NSString *commandString = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];

      [self log: @"Terminal: Unhandled CSI %@%c (%02u/%02u).", commandString, finalByte, finalByte / 16, finalByte % 16];
    }
  }

  [_commandBuffer replaceBytesInRange: NSMakeRange (0, _commandBuffer.length) withBytes: NULL length: 0];
}

- (void) processPseudoANSIMusic
{
#ifdef DEBUG_LOG_PSEUDO_ANSI_MUSIC
  NSString *commandString = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];
  [self log: @"Terminal: Pseudo-ANSI Music %@.", commandString];
#endif

  [_commandBuffer replaceBytesInRange: NSMakeRange (0, _commandBuffer.length) withBytes: NULL length: 0];
}

- (void) reset
{
  [_terminalStateMachine reset];
  [self _setUpInitialTextAttributes];
}

- (void) setStringEncoding: (NSStringEncoding) stringEncoding
{
  [self.protocolStack flushBufferedData];
  _connectionState.stringEncoding = stringEncoding;
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
  _textAttributes[MUCustomForegroundColorAttributeName] = @(MUColorTagDefaultForeground);
  _textAttributes[MUCustomBackgroundColorAttributeName] = @(MUColorTagDefaultBackground);
}

- (void) _updateColorsForANSIColor: (MUAbstractANSIColor) color
{
  NSColor *specifiedColor;
  MUColorTag colorTagForANSI256;
  MUColorTag colorTagForANSI16;
  BOOL changeIfBright;

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  switch (color)
  {
    case MUANSIColorBlack:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
      colorTagForANSI256 = MUColorTagANSI256Black;
      colorTagForANSI16 = MUColorTagANSIBlack;
      changeIfBright = NO;
      break;

    case MUANSIColorRed:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
      colorTagForANSI256 = MUColorTagANSI256Red;
      colorTagForANSI16 = MUColorTagANSIRed;
      changeIfBright = NO;
      break;

    case MUANSIColorGreen:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
      colorTagForANSI256 = MUColorTagANSI256Green;
      colorTagForANSI16 = MUColorTagANSIGreen;
      changeIfBright = NO;
      break;

    case MUANSIColorYellow:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
      colorTagForANSI256 = MUColorTagANSI256Yellow;
      colorTagForANSI16 = MUColorTagANSIYellow;
      changeIfBright = NO;
      break;

    case MUANSIColorBlue:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
      colorTagForANSI256 = MUColorTagANSI256Blue;
      colorTagForANSI16 = MUColorTagANSIBlue;
      changeIfBright = NO;
      break;

    case MUANSIColorMagenta:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
      colorTagForANSI256 = MUColorTagANSI256Magenta;
      colorTagForANSI16 = MUColorTagANSIMagenta;
      changeIfBright = NO;
      break;

    case MUANSIColorCyan:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
      colorTagForANSI256 = MUColorTagANSI256Cyan;
      colorTagForANSI16 = MUColorTagANSICyan;
      changeIfBright = NO;
      break;

    case MUANSIColorWhite:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
      colorTagForANSI256 = MUColorTagANSI256White;
      colorTagForANSI16 = MUColorTagANSIWhite;
      changeIfBright = NO;
      break;

    case MUANSIColorBrightBlack:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
      colorTagForANSI256 = MUColorTagANSIBrightBlack;
      colorTagForANSI16 = MUColorTagANSIBlack;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightRed:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
      colorTagForANSI256 = MUColorTagANSIBrightRed;
      colorTagForANSI16 = MUColorTagANSIRed;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightGreen:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
      colorTagForANSI256 = MUColorTagANSIBrightGreen;
      colorTagForANSI16 = MUColorTagANSIGreen;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightYellow:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
      colorTagForANSI256 = MUColorTagANSIBrightYellow;
      colorTagForANSI16 = MUColorTagANSIYellow;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightBlue:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
      colorTagForANSI256 = MUColorTagANSIBrightBlue;
      colorTagForANSI16 = MUColorTagANSIBlue;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightMagenta:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
      colorTagForANSI256 = MUColorTagANSIBrightMagenta;
      colorTagForANSI16 = MUColorTagANSIMagenta;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightCyan:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
      colorTagForANSI256 = MUColorTagANSIBrightCyan;
      colorTagForANSI16 = MUColorTagANSICyan;
      changeIfBright = YES;
      break;

    case MUANSIColorBrightWhite:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
      colorTagForANSI256 = MUColorTagANSIBrightWhite;
      colorTagForANSI16 = MUColorTagANSIWhite;
      changeIfBright = YES;
      break;

    default:
      return;
  }

  if ([_textAttributes[MUCustomForegroundColorAttributeName] intValue] == colorTagForANSI256
      || ([_textAttributes[MUCustomForegroundColorAttributeName] intValue] == colorTagForANSI16
          && ((changeIfBright && _textAttributes[MUBrightColorAttributeName])
              || (!changeIfBright && !_textAttributes[MUBrightColorAttributeName]))))
  {
    if (_textAttributes[MUInverseColorsAttributeName])
      _textAttributes[NSBackgroundColorAttributeName] = specifiedColor;
    else
      _textAttributes[NSForegroundColorAttributeName] = specifiedColor;
  }

  if ([_textAttributes[MUCustomBackgroundColorAttributeName] intValue] == colorTagForANSI256
      || ([_textAttributes[MUCustomBackgroundColorAttributeName] intValue] == colorTagForANSI16
          && (!changeIfBright && !_textAttributes[MUBrightColorAttributeName])))
  {
    if (_textAttributes[MUInverseColorsAttributeName])
      _textAttributes[NSForegroundColorAttributeName] = specifiedColor;
    else
      _textAttributes[NSBackgroundColorAttributeName] = specifiedColor;
  }
}

- (void) _updateDisplayBrightAsBold
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if (_textAttributes[MUBrightColorAttributeName] && [defaults boolForKey: MUPDisplayBrightAsBold])
    _textAttributes[NSFontAttributeName] = [_textAttributes[NSFontAttributeName] boldFontWithRespectTo: _profile.effectiveFont];
  else
    _textAttributes[NSFontAttributeName] = [_textAttributes[NSFontAttributeName] unboldFontWithRespectTo: _profile.effectiveFont];
}

- (void) _updateTextAttributesFromProfileBackgroundColor
{
  if (_textAttributes[MUInverseColorsAttributeName]
      && [_textAttributes[MUCustomBackgroundColorAttributeName] intValue] == MUColorTagDefaultBackground)
  {
    _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveBackgroundColor;
  }
}

- (void) _updateTextAttributesFromProfileFont
{
  NSFont *newEffectiveFont;

  if (_textAttributes[MUBrightColorAttributeName]
      || ([[NSUserDefaults standardUserDefaults] boolForKey: MUPDisplayBrightAsBold]
          && ([_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightBlack
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightBlue
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightCyan
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightGreen
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightMagenta
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightRed
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightWhite
              || [_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagANSIBrightYellow)))
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
  if ([_textAttributes[MUCustomForegroundColorAttributeName] intValue] == MUColorTagDefaultForeground)
  {
    if (_textAttributes[MUInverseColorsAttributeName])
      _textAttributes[NSBackgroundColorAttributeName] = _profile.effectiveTextColor;
    else
      _textAttributes[NSForegroundColorAttributeName] = _profile.effectiveTextColor;
  }
}

#pragma mark - ANSI CSI codes

- (void) _handleANSICursorRight
{
  [self.protocolStack flushBufferedData];

  @synchronized (_textAttributes)
  {
    NSMutableDictionary *savedAttributes = [_textAttributes mutableCopy];

    // We clear the background color attributes here because some lazy ANSI code doesn't clear inverse mode after it's
    // done using it.

    [_textAttributes removeObjectForKey: MUInverseColorsAttributeName];
    [_textAttributes removeObjectForKey: NSBackgroundColorAttributeName];
    _textAttributes[MUCustomBackgroundColorAttributeName] = @(MUColorTagDefaultBackground);
    
    NSString *commandCode = [[NSString alloc] initWithData: _commandBuffer encoding: NSASCIIStringEncoding];
    NSInteger numberOfSpaces = commandCode.integerValue;
    
    if (numberOfSpaces > 0)
    {
      for (NSInteger i = 0; i < numberOfSpaces; i++)
        PASS_ON_PARSED_BYTE (' ');
    }
    
    [self.protocolStack flushBufferedData];
    
    _textAttributes = savedAttributes;
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
        MUColorTag colorTag = MUColorTagUndefined;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        switch (colorCode)
        {
          case MUANSI256Black:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
            colorTag = MUColorTagANSI256Black;
            break;

          case MUANSI256BrightBlack:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
            colorTag = MUColorTagANSIBrightBlack;
            break;

          case MUANSI256Red:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
            colorTag = MUColorTagANSI256Red;
            break;

          case MUANSI256BrightRed:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
            colorTag = MUColorTagANSIBrightRed;
            break;

          case MUANSI256Green:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
            colorTag = MUColorTagANSI256Green;
            break;

          case MUANSI256BrightGreen:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
            colorTag = MUColorTagANSIBrightGreen;
            break;

          case MUANSI256Yellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
            colorTag = MUColorTagANSI256Yellow;
            break;

          case MUANSI256BrightYellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
            colorTag = MUColorTagANSIBrightYellow;
            break;

          case MUANSI256Blue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
            colorTag = MUColorTagANSI256Blue;
            break;

          case MUANSI256BrightBlue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
            colorTag = MUColorTagANSIBrightBlue;
            break;

          case MUANSI256Magenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
            colorTag = MUColorTagANSI256Magenta;
            break;

          case MUANSI256BrightMagenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
            colorTag = MUColorTagANSIBrightMagenta;
            break;

          case MUANSI256Cyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
            colorTag = MUColorTagANSI256Cyan;
            break;

          case MUANSI256BrightCyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
            colorTag = MUColorTagANSIBrightCyan;
            break;

          case MUANSI256White:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
            colorTag = MUColorTagANSI256White;
            break;

          case MUANSI256BrightWhite:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
            colorTag = MUColorTagANSIBrightWhite;
            break;
        }

        [self _setForegroundColor: targetColor colorTag: colorTag];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        [self _setForegroundColor: [NSColor ANSI256ColorCubeColorForCode: (uint8_t) colorCode]
                   colorTag: MUColorTagANSI256Fixed];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        [self _setForegroundColor: [NSColor ANSI256GrayscaleColorForCode: (uint8_t) colorCode]
                   colorTag: MUColorTagANSI256Fixed];
      }

      return;
    }
    else if ([codeComponents[0] intValue] == MUANSIBackground256)
    {
      int colorCode = [codeComponents[2] intValue];

      if (colorCode >= 0 && colorCode < 16)
      {
        NSColor *targetColor;
        MUColorTag colorTag = MUColorTagUndefined;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        switch (colorCode)
        {
          case MUANSI256Black:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
            colorTag = MUColorTagANSI256Black;
            break;

          case MUANSI256BrightBlack:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
            colorTag = MUColorTagANSIBrightBlack;
            break;

          case MUANSI256Red:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
            colorTag = MUColorTagANSI256Red;
            break;

          case MUANSI256BrightRed:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
            colorTag = MUColorTagANSIBrightRed;
            break;

          case MUANSI256Green:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
            colorTag = MUColorTagANSI256Green;
            break;

          case MUANSI256BrightGreen:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
            colorTag = MUColorTagANSIBrightGreen;
            break;

          case MUANSI256Yellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
            colorTag = MUColorTagANSI256Yellow;
            break;

          case MUANSI256BrightYellow:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
            colorTag = MUColorTagANSIBrightYellow;
            break;

          case MUANSI256Blue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
            colorTag = MUColorTagANSI256Blue;
            break;

          case MUANSI256BrightBlue:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
            colorTag = MUColorTagANSIBrightBlue;
            break;

          case MUANSI256Magenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
            colorTag = MUColorTagANSI256Magenta;
            break;

          case MUANSI256BrightMagenta:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
            colorTag = MUColorTagANSIBrightMagenta;
            break;

          case MUANSI256Cyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
            colorTag = MUColorTagANSI256Cyan;
            break;

          case MUANSI256BrightCyan:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
            colorTag = MUColorTagANSIBrightCyan;
            break;

          case MUANSI256White:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
            colorTag = MUColorTagANSI256White;
            break;

          case MUANSI256BrightWhite:
            targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
            colorTag = MUColorTagANSIBrightWhite;
            break;
        }

        [self _setBackgroundColor: targetColor colorTag: colorTag];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        [self _setBackgroundColor: [NSColor ANSI256ColorCubeColorForCode: (uint8_t) colorCode]
                   colorTag: MUColorTagANSI256Fixed];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        [self _setBackgroundColor: [NSColor ANSI256GrayscaleColorForCode: (uint8_t) colorCode]
                   colorTag: MUColorTagANSI256Fixed];
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

      case MUANSIBrightOn:
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
        _textAttributes[NSStrikethroughStyleAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleSingle);
        break;

      case MUANSIDoubleUnderlineOn:
        _textAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlinePatternSolid | NSUnderlineStyleDouble);
        break;

      case MUANSIBrightOff:
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIBlack];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIRed];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIGreen];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIYellow];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIBlue];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIMagenta];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSICyan];
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

        [self _setForegroundColor: color colorTag: MUColorTagANSIWhite];
        break;
      }

      case MUANSIForegroundDefault:
        [self _unsetForegroundColor];
        break;

      case MUANSIBackgroundBlack:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBlack];
        break;
      }

      case MUANSIBackgroundRed:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIRed];
        break;
      }

      case MUANSIBackgroundGreen:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIGreen];
        break;
      }

      case MUANSIBackgroundYellow:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIYellow];
        break;
      }

      case MUANSIBackgroundBlue:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBlue];
        break;
      }

      case MUANSIBackgroundMagenta:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIMagenta];
        break;
      }

      case MUANSIBackgroundCyan:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSICyan];
        break;
      }

      case MUANSIBackgroundWhite:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIWhite];
        break;
      }
        
      case MUANSIBackgroundDefault:
        [self _unsetBackgroundColor];
        break;

      case MUANSIForegroundBrightBlack:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightBlack];
        break;
      }

      case MUANSIForegroundBrightRed:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightRed];
        break;
      }

      case MUANSIForegroundBrightGreen:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightGreen];
        break;
      }

      case MUANSIForegroundBrightYellow:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightYellow];
        break;
      }

      case MUANSIForegroundBrightBlue:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightBlue];
        break;
      }

      case MUANSIForegroundBrightMagenta:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightMagenta];
        break;
      }

      case MUANSIForegroundBrightCyan:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightCyan];
        break;
      }

      case MUANSIForegroundBrightWhite:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];

        [self _setForegroundColor: color colorTag: MUColorTagANSIBrightWhite];
        break;
      }

      case MUANSIBackgroundBrightBlack:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightBlack];
        break;
      }

      case MUANSIBackgroundBrightRed:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightRed];
        break;
      }

      case MUANSIBackgroundBrightGreen:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightGreen];
        break;
      }

      case MUANSIBackgroundBrightYellow:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightYellow];
        break;
      }

      case MUANSIBackgroundBrightBlue:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightBlue];
        break;
      }

      case MUANSIBackgroundBrightMagenta:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightMagenta];
        break;
      }

      case MUANSIBackgroundBrightCyan:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];

        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightCyan];
        break;
      }

      case MUANSIBackgroundBrightWhite:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
        
        [self _setBackgroundColor: color colorTag: MUColorTagANSIBrightWhite];
        break;
      }

      default:
        [self log: @"Terminal: Unhandled ANSI SGR Code: %@.", code];
        break;
    }
  }
}

- (void) _setBackgroundColor: (NSColor *) color colorTag: (MUColorTag) colorTag
{
  if (colorTag == MUColorTagUndefined)
    return;
  
  _textAttributes[MUCustomBackgroundColorAttributeName] = @(colorTag);

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
    case MUColorTagANSIBlack:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
      break;

    case MUColorTagANSIRed:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
      break;

    case MUColorTagANSIGreen:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
      break;

    case MUColorTagANSIYellow:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
      break;

    case MUColorTagANSIBlue:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
      break;

    case MUColorTagANSIMagenta:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
      break;

    case MUColorTagANSICyan:
      color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
      break;

    case MUColorTagANSIWhite:
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

- (void) _setForegroundColor: (NSColor *) color colorTag: (MUColorTag) colorTag
{
  if (colorTag == MUColorTagUndefined)
    return;
  
  _textAttributes[MUCustomForegroundColorAttributeName] = @(colorTag);

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
  _textAttributes[MUCustomBackgroundColorAttributeName] = @(MUColorTagDefaultBackground);

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
      case MUColorTagANSIBlack:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
        break;

      case MUColorTagANSIRed:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
        break;

      case MUColorTagANSIGreen:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
        break;

      case MUColorTagANSIYellow:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
        break;

      case MUColorTagANSIBlue:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
        break;

      case MUColorTagANSIMagenta:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
        break;

      case MUColorTagANSICyan:
        color = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
        break;

      case MUColorTagANSIWhite:
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
  _textAttributes[MUCustomForegroundColorAttributeName] = @(MUColorTagDefaultForeground);

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

    if ([_textAttributes[MUCustomBackgroundColorAttributeName] intValue] == MUColorTagDefaultBackground)
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
