//
// MUANSIFormattingFilter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUANSIFormattingFilter.h"
#import "NSColor (ANSI).h"
#import "NSFont (Traits).h"

static NSString * const MUANSIResetAttributeName = @"MUANSIResetAttributeName";

@interface MUANSIFormattingFilter ()
{
  BOOL _inCode;
  NSString *_ansiCode;
  NSMutableDictionary *_currentAttributes;
}

@property (strong, nonatomic) MUProfile *profile;

// This is the main routine to process codes and apply them to the string. A YES return means there are more codes left,
// a NO return means we're done.
- (BOOL) _processOneANSICode: (NSMutableAttributedString *) editString;

- (void) _applyCode: (unichar) code
           toString: (NSMutableAttributedString *) mutableString
         atLocation: (NSUInteger) startLocation;
- (NSUInteger) _scanUpToCodeInString: (NSString *) string;
- (NSUInteger) _scanThroughEndOfCodeAtLocation: (NSUInteger) location inString: (NSString *) string;
- (void) _updateFromProfileFont;
- (void) _updateFromProfileTextColor;

#pragma mark - Font attribute manipulation

- (void) removeAttribute: (NSString *) attribute
                inString: (NSMutableAttributedString *) string
            fromLocation: (NSUInteger) startLocation;
- (void) resetAllAttributesInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetBackgroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetBoldInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetCustomColorInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetFontInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetUnderlineInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) setAttribute: (NSString *) attribute
              toValue: (id) value
             inString: (NSMutableAttributedString *) string
         fromLocation: (NSUInteger) startLocation;
- (void) setAttributes: (NSDictionary *) attributes
              onString: (NSMutableAttributedString *) string
          fromLocation: (NSUInteger) startLocation;
- (void) _setAttributesInString: (NSMutableAttributedString *) string atLocation: (NSUInteger) startLocation;

@end

#pragma mark -

@implementation MUANSIFormattingFilter

+ (MUFilter *) filterWithProfile: (MUProfile *) newProfile
                        delegate: (NSObject <MUANSIFormattingFilterDelegate> *) newDelegate
{
  return [[self alloc] initWithProfile: newProfile delegate: newDelegate];
}

- (id) initWithProfile: (MUProfile *) newProfile
              delegate: (NSObject <MUANSIFormattingFilterDelegate> *) newDelegate
{
  if (!newProfile)
    return nil;
  
  if (!(self = [super init]))
    return nil;
  
  _profile = newProfile;
  _delegate = newDelegate;
  
  _ansiCode = @"";
  _inCode = NO;
  
  _currentAttributes = [[NSMutableDictionary alloc] init];
  [_currentAttributes setValue: _profile.effectiveFont forKey: NSFontAttributeName];
  [_currentAttributes setValue: _profile.effectiveTextColor forKey: NSForegroundColorAttributeName];
  
  [self.profile addObserver: self forKeyPath: @"effectiveFont" options: NSKeyValueObservingOptionNew context: NULL];
  [self.profile addObserver: self forKeyPath: @"effectiveTextColor" options: NSKeyValueObservingOptionNew context: NULL];
  
  return self;
}

- (void) dealloc
{
  [self.profile removeObserver: self forKeyPath: @"effectiveFont"];
  [self.profile removeObserver: self forKeyPath: @"effectiveTextColor"];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == _profile)
  {
    if ([keyPath isEqualToString: @"effectiveFont"])
    {
      [self _updateFromProfileFont];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveTextColor"])
    {
      [self _updateFromProfileTextColor];
      return;
    }
  }
  
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSMutableAttributedString *editString = [attributedString mutableCopy];
  
  [self setAttributes: _currentAttributes onString: editString fromLocation: 0];
  
  while ([self _processOneANSICode: editString])
    ;
  
  return editString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  NSMutableDictionary *savedAttributes = [_currentAttributes mutableCopy];
  
  NSAttributedString *filteredString = [self filterCompleteLine: attributedString];
  
  _currentAttributes = savedAttributes;
  
  return filteredString;
}

#pragma mark - Private methods

- (void) _applyCode: (unichar) code
           toString: (NSMutableAttributedString *) mutableString
         atLocation: (NSUInteger) startLocation
{
  switch (code)
  {
    case MUANSISelectGraphicRendition:
      [self _setAttributesInString: mutableString atLocation: startLocation];
      return;
      
    case MUANSIEraseData:
      if (_ansiCode.length == 3)
      {
        if ([_ansiCode characterAtIndex: 2] == '1' || [_ansiCode characterAtIndex: 2] == '2')
        {
          [mutableString deleteCharactersInRange: NSMakeRange (0, startLocation)];
          if ([self.delegate respondsToSelector: @selector (clearScreen)])
            [self.delegate clearScreen];
        }
      }
      return;
      
    default:
      NSLog (@"Received unhandled ANSI command: ESC%@%C", [_ansiCode substringFromIndex: 1], code);
      return;
  }
}

- (BOOL) _processOneANSICode: (NSMutableAttributedString *) editString
{
  NSRange codeRange;
  
  if (!_inCode)
  {
    codeRange.location = [self _scanUpToCodeInString: editString.string];
    
    _ansiCode = @"";
  }
  else
    codeRange.location = 0;
  
  if (codeRange.location != NSNotFound)
  {
    _inCode = YES;
    codeRange.length = [self _scanThroughEndOfCodeAtLocation: codeRange.location
                                                    inString: editString.string];
    
    if (codeRange.length == NSNotFound)
    {
      codeRange.length = editString.length - codeRange.location;
      [editString deleteCharactersInRange: codeRange];
      return NO;
    }
    
    if (codeRange.location < editString.length)
    {
      unichar code = [editString.string characterAtIndex: codeRange.location + codeRange.length - 1];
      
      [editString deleteCharactersInRange: codeRange];
      [self _applyCode: code toString: editString atLocation: codeRange.location];
      
      _inCode = NO;
      _ansiCode = @"";
      
      return YES;
    }
  }
  
  return NO;
}

- (NSUInteger) _scanUpToCodeInString: (NSString *) string
{
  NSScanner *scanner = [NSScanner scannerWithString: string];
  
  scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString: @""];
  
  NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString: @"\x1B"];
  NSRange stopRange = [string rangeOfCharacterFromSet: stopSet];
  
  if (stopRange.location == NSNotFound)
    return NSNotFound;
  
  while ([scanner scanUpToCharactersFromSet: stopSet intoString: nil])
    ;
  
  return scanner.scanLocation;
}

- (NSUInteger) _scanThroughEndOfCodeAtLocation: (NSUInteger) location inString: (NSString *) string
{
  NSScanner *scanner = [NSScanner scannerWithString: string];
  
  scanner.scanLocation = location;
  scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString: @""];
  
  NSCharacterSet *resumeSet;
  
  if (string.length >= location + 3
      && [string characterAtIndex: location + 1] == '['
      && [string characterAtIndex: location + 2] == 'M')
  {
    // This is the starter code for "ANSI" music, which is defined to terminate with a \u000e. (Octal 016.)
    // \u000e is translated into \u266b (Unicode BEAMED EIGHTH NOTES) by IBM Code Page 437 translation, so we break on
    // either one.
    //
    // This is not a valid ANSI sequence, since it has non-numeric arguments, but life is just hard sometimes.
    
    resumeSet = [NSCharacterSet characterSetWithCharactersInString: @"\016\u266b"];
  }
  else
    resumeSet = [NSCharacterSet characterSetWithCharactersInString: @"\007ABCDEFGHJKSTfhlmnsuz"];
  
  NSString *charactersFromThisScan;
  [scanner scanUpToCharactersFromSet: resumeSet intoString: &charactersFromThisScan];
  
  _ansiCode = [NSString stringWithFormat: @"%@%@", _ansiCode, charactersFromThisScan];
  
  if (scanner.scanLocation == string.length)
    return NSNotFound;
  else
    return charactersFromThisScan.length + 1;
}

- (void) _updateFromProfileFont
{
  NSFont *newEffectiveFont;
  
  if (_currentAttributes[MUBoldFontAttributeName])
    newEffectiveFont = [_profile.effectiveFont boldFontWithRespectTo: _profile.effectiveFont];
  else
    newEffectiveFont = _profile.effectiveFont;
  
  _currentAttributes[NSFontAttributeName] = newEffectiveFont;
}

- (void) _updateFromProfileTextColor
{
  if (!_currentAttributes[MUCustomColorAttributeName])
    _currentAttributes[NSForegroundColorAttributeName] = _profile.effectiveTextColor;
}

#pragma mark - Attribute manipulation

- (void) removeAttribute: (NSString *) attribute
                inString: (NSMutableAttributedString *) string
            fromLocation: (NSUInteger) startLocation
{
  [string removeAttribute: attribute
                    range: NSMakeRange (startLocation, string.length - startLocation)];
  [_currentAttributes removeObjectForKey: attribute];
}

- (void) resetAllAttributesInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self resetBackgroundInString: string fromLocation: startLocation];
  [self resetBoldInString: string fromLocation: startLocation];
  [self resetCustomColorInString: string fromLocation: startLocation];
  [self resetForegroundInString: string fromLocation: startLocation];
  [self resetFontInString: string fromLocation: startLocation];
  [self resetUnderlineInString: string fromLocation: startLocation];
}

- (void) resetBackgroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self removeAttribute: NSBackgroundColorAttributeName inString: string fromLocation: startLocation];
}

- (void) resetBoldInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self removeAttribute: MUBoldFontAttributeName inString: string fromLocation: startLocation];
}

- (void) resetCustomColorInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self removeAttribute: MUCustomColorAttributeName inString: string fromLocation: startLocation];
}

- (void) resetFontInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self setAttribute: NSFontAttributeName
             toValue: _profile.effectiveFont
            inString: string
        fromLocation: startLocation];
}

- (void) resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self setAttribute: NSForegroundColorAttributeName
             toValue: _profile.effectiveTextColor
            inString: string
        fromLocation: startLocation];
}

- (void) resetUnderlineInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self removeAttribute: NSUnderlineStyleAttributeName inString: string fromLocation: startLocation];
}

- (void) setAttribute: (NSString *) attribute
              toValue: (id) value
             inString: (NSMutableAttributedString *) string
         fromLocation: (NSUInteger) startLocation
{
  [string addAttribute: attribute
                 value: value
                 range: NSMakeRange (startLocation, string.length - startLocation)];
  _currentAttributes[attribute] = value;
}

- (void) setAttributes: (NSDictionary *) attributes
              onString: (NSMutableAttributedString *) string
          fromLocation: (NSUInteger) startLocation
{
  for (NSString *key in attributes.allKeys)
  {
    [self setAttribute: key
               toValue: [attributes valueForKey: key]
              inString: string
          fromLocation: startLocation];
  }
}

- (void) _setAttributesInString: (NSMutableAttributedString *) string atLocation: (NSUInteger) startLocation
{
  if (string.length <= startLocation)
    return;
  
  NSArray *codeComponents = [[_ansiCode substringFromIndex: 2] componentsSeparatedByString: @";"];
  
  if (codeComponents.count == 3 && [codeComponents[1] intValue] == 5)
  {
    if ([codeComponents[0] intValue] == MUANSIForeground256)
    {
      int colorCode = [codeComponents[2] intValue];
      
      if (colorCode >= 0 && colorCode < 16)
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];

        NSColor *targetColor;
        
        switch (colorCode)
        {
          case MUANSI256Black:
            targetColor = [NSColor ANSIBlackColor];
            break;
            
          case MUANSI256BrightBlack:
            targetColor = [NSColor ANSIBrightBlackColor];
            break;
            
          case MUANSI256Red:
            targetColor = [NSColor ANSIRedColor];
            break;
            
          case MUANSI256BrightRed:
            targetColor = [NSColor ANSIBrightRedColor];
            break;
            
          case MUANSI256Green:
            targetColor = [NSColor ANSIGreenColor];
            break;
            
          case MUANSI256BrightGreen:
            targetColor = [NSColor ANSIBrightGreenColor];
            break;
            
          case MUANSI256Yellow:
            targetColor = [NSColor ANSIYellowColor];
            break;
            
          case MUANSI256BrightYellow:
            targetColor = [NSColor ANSIBrightYellowColor];
            break;
            
          case MUANSI256Blue:
            targetColor = [NSColor ANSIBlueColor];
            break;
            
          case MUANSI256BrightBlue:
            targetColor = [NSColor ANSIBrightBlueColor];
            break;
            
          case MUANSI256Magenta:
            targetColor = [NSColor ANSIMagentaColor];
            break;
            
          case MUANSI256BrightMagenta:
            targetColor = [NSColor ANSIBrightMagentaColor];
            break;
            
          case MUANSI256Cyan:
            targetColor = [NSColor ANSICyanColor];
            break;
            
          case MUANSI256BrightCyan:
            targetColor = [NSColor ANSIBrightCyanColor];
            break;
            
          case MUANSI256White:
            targetColor = [NSColor ANSIWhiteColor];
            break;
            
          case MUANSI256BrightWhite:
            targetColor = [NSColor ANSIBrightWhiteColor];
            break;
        }
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        int adjustedValue = colorCode - 16;
        int red = adjustedValue / 36;
        int green = (adjustedValue % 36) / 6;
        int blue = (adjustedValue % 36) % 6;
        
        NSColor *cubeColor = [NSColor colorWithCalibratedRed: 1.0 / 6.0 * red
                                                       green: 1.0 / 6.0 * green
                                                        blue: 1.0 / 6.0 * blue
                                                       alpha: 1.0];
        
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: cubeColor
                  inString: string
              fromLocation: startLocation];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        int adjustedValue = colorCode - 231;
        
        NSColor *grayscaleColor = [NSColor colorWithCalibratedWhite: 1.0 / 25.0 * adjustedValue
                                                              alpha: 1.0];
        
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: grayscaleColor
                  inString: string
              fromLocation: startLocation];
      }
      
      return;
    }
    else if ([codeComponents[0] intValue] == MUANSIBackground256)
    {
      int colorCode = [codeComponents[2] intValue];
      
      if (colorCode >= 0 && colorCode < 16)
      {
        NSColor *targetColor;
        
        switch (colorCode)
        {
          case MUANSI256Black:
            targetColor = [NSColor ANSIBlackColor];
            break;
            
          case MUANSI256BrightBlack:
            targetColor = [NSColor ANSIBrightBlackColor];
            break;
            
          case MUANSI256Red:
            targetColor = [NSColor ANSIRedColor];
            break;
            
          case MUANSI256BrightRed:
            targetColor = [NSColor ANSIBrightRedColor];
            break;
            
          case MUANSI256Green:
            targetColor = [NSColor ANSIGreenColor];
            break;
            
          case MUANSI256BrightGreen:
            targetColor = [NSColor ANSIBrightGreenColor];
            break;
            
          case MUANSI256Yellow:
            targetColor = [NSColor ANSIYellowColor];
            break;
            
          case MUANSI256BrightYellow:
            targetColor = [NSColor ANSIBrightYellowColor];
            break;
            
          case MUANSI256Blue:
            targetColor = [NSColor ANSIBlueColor];
            break;
            
          case MUANSI256BrightBlue:
            targetColor = [NSColor ANSIBrightBlueColor];
            break;
            
          case MUANSI256Magenta:
            targetColor = [NSColor ANSIMagentaColor];
            break;
            
          case MUANSI256BrightMagenta:
            targetColor = [NSColor ANSIBrightMagentaColor];
            break;
            
          case MUANSI256Cyan:
            targetColor = [NSColor ANSICyanColor];
            break;
            
          case MUANSI256BrightCyan:
            targetColor = [NSColor ANSIBrightCyanColor];
            break;
            
          case MUANSI256White:
            targetColor = [NSColor ANSIWhiteColor];
            break;
            
          case MUANSI256BrightWhite:
            targetColor = [NSColor ANSIBrightWhiteColor];
            break;
        }
        
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        int adjustedValue = colorCode - 16;
        int red = adjustedValue / 36;
        int green = (adjustedValue % 36) / 6;
        int blue = (adjustedValue % 36) % 6;
        
        NSColor *cubeColor = [NSColor colorWithCalibratedRed: 1.0 / 6.0 * red
                                                       green: 1.0 / 6.0 * green
                                                        blue: 1.0 / 6.0 * blue
                                                       alpha: 1.0];
        
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: cubeColor
                  inString: string
              fromLocation: startLocation];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        int adjustedValue = colorCode - 231;
        
        NSColor *grayscaleColor = [NSColor colorWithCalibratedWhite: 1.0 / 25.0 * adjustedValue
                                                              alpha: 1.0];
        
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: grayscaleColor
                  inString: string
              fromLocation: startLocation];
      }

      return;
    }
  }
  
  for (NSString *code in codeComponents)
  {
    switch ([code intValue])
    {
      case MUANSIReset:
        [self resetAllAttributesInString: string fromLocation: startLocation];
        break;
        
      case MUANSIBoldOn:
        [self setAttribute: MUBoldFontAttributeName toValue: @YES inString: string fromLocation: startLocation];
        [self setAttribute: NSFontAttributeName
                   toValue: [_currentAttributes[NSFontAttributeName] boldFontWithRespectTo: _profile.effectiveFont]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIUnderlineOn:
      {
        [self setAttribute: NSUnderlineStyleAttributeName
                   toValue: @(NSUnderlineStyleSingle)
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIBoldOff:
        [self resetBoldInString: string fromLocation: startLocation];
        [self resetFontInString: string fromLocation: startLocation];
        break;
        
      case MUANSIUnderlineOff:
        [self resetUnderlineInString: string fromLocation: startLocation];
        break;
        
      case MUANSIForegroundBlack:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightBlackColor];
        else
          targetColor = [NSColor ANSIBlackColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundRed:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightRedColor];
        else
          targetColor = [NSColor ANSIRedColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundGreen:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightGreenColor];
        else
          targetColor = [NSColor ANSIGreenColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundYellow:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightYellowColor];
        else
          targetColor = [NSColor ANSIYellowColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundBlue:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightBlueColor];
        else
          targetColor = [NSColor ANSIBlueColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundMagenta:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightMagentaColor];
        else
          targetColor = [NSColor ANSIMagentaColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundCyan:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightCyanColor];
        else
          targetColor = [NSColor ANSICyanColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundWhite:
      {
        [self setAttribute: MUCustomColorAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *targetColor;
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSColor ANSIBrightWhiteColor];
        else
          targetColor = [NSColor ANSIWhiteColor];
        
        [self setAttribute: NSForegroundColorAttributeName
                   toValue: targetColor
                  inString: string
              fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundDefault:
        [self resetCustomColorInString: string fromLocation: startLocation];
        [self resetForegroundInString: string fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundBlack:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIBlackColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundRed:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIRedColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundGreen:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIGreenColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundYellow:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIYellowColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundBlue:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIBlueColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundMagenta:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIMagentaColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundCyan:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSICyanColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundWhite:
        [self setAttribute: NSBackgroundColorAttributeName
                   toValue: [NSColor ANSIWhiteColor]
                  inString: string
              fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundDefault:
        [self resetBackgroundInString: string fromLocation: startLocation];
        break;
        
      default:
        NSLog (@"Received unhandled ANSI SGR command: %i", code.intValue);
        break;
    }
  }
}

@end
