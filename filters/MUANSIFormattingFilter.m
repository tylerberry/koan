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
- (void) _updateFromProfileBackgroundColor;
- (void) _updateFromProfileFont;
- (void) _updateFromProfileTextColor;

#pragma mark - Font attribute manipulation

- (void) _removeAttribute: (NSString *) attribute
                 inString: (NSMutableAttributedString *) string
             fromLocation: (NSUInteger) startLocation;

- (void) _resetBackgroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetBlinkInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetBoldInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetHiddenTextInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetInverseInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetItalicInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetStrikethroughInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) _resetUnderlineInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;

- (void) _setAttribute: (NSString *) attribute
               toValue: (id) value
              inString: (NSMutableAttributedString *) string
          fromLocation: (NSUInteger) startLocation;
- (void) _setAttributes: (NSDictionary *) attributes
               inString: (NSMutableAttributedString *) string
           fromLocation: (NSUInteger) startLocation;
- (void) _setAttributesInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;

- (void) _setBackgroundColor: (NSColor *) color
              customColorTag: (enum MUCustomColorTags) customColorTag
                    inString: (NSMutableAttributedString *) string
                fromLocation: (NSUInteger) startLocation;
- (void) _setBoldInString: (NSMutableAttributedString *) string
             fromLocation: (NSUInteger) startLocation;
- (void) _setForegroundColor: (NSColor *) color
              customColorTag: (enum MUCustomColorTags) customColorTag
                    inString: (NSMutableAttributedString *) string
                fromLocation: (NSUInteger) startLocation;

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
  [_currentAttributes setValue: @(MUDefaultBackgroundColorTag) forKey: MUCustomBackgroundColorAttributeName];
  [_currentAttributes setValue: @(MUDefaultForegroundColorTag) forKey: MUCustomForegroundColorAttributeName];
  
  [self.profile addObserver: self forKeyPath: @"effectiveBackgroundColor" options: NSKeyValueObservingOptionNew context: NULL];
  [self.profile addObserver: self forKeyPath: @"effectiveFont" options: NSKeyValueObservingOptionNew context: NULL];
  [self.profile addObserver: self forKeyPath: @"effectiveTextColor" options: NSKeyValueObservingOptionNew context: NULL];
  
  return self;
}

- (void) dealloc
{
  [self.profile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
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
    if ([keyPath isEqualToString: @"effectiveBackgroundColor"])
    {
      [self _updateFromProfileBackgroundColor];
      return;
    }
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
  
  [self _setAttributes: _currentAttributes inString: editString fromLocation: 0];
  
  while ([self _processOneANSICode: editString])
    ;
  
  // Background color should never be set on a trailing newline, because it causes the color to stretch to the edge of
  // the window. In order to preserve this change during future font or color changes, we remove all color-relevant
  // attributes from the newline.
  
  if (editString.length != 0 && [editString.string characterAtIndex: editString.length - 1] == '\n')
  {
    NSRange lastCharacterRange = NSMakeRange (editString.length - 1, 1);
    
    [editString addAttribute: NSForegroundColorAttributeName
                       value: _profile.effectiveTextColor
                       range: lastCharacterRange];
    [editString addAttribute: MUCustomForegroundColorAttributeName
                       value: @(MUDefaultForegroundColorTag)
                       range: lastCharacterRange];
    
    [editString removeAttribute: NSBackgroundColorAttributeName
                          range: lastCharacterRange];
    
    [editString removeAttribute: MUInverseColorsAttributeName range: lastCharacterRange];
  }
  
  return editString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  NSMutableDictionary *savedAttributes = [_currentAttributes mutableCopy];
  NSString *savedANSICode = [_ansiCode copy];
  BOOL savedInCode = _inCode;
  
  NSAttributedString *filteredString = [self filterCompleteLine: attributedString];
  
  _currentAttributes = savedAttributes;
  _ansiCode = savedANSICode;
  _inCode = savedInCode;
  
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
      [self _setAttributesInString: mutableString fromLocation: startLocation];
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

- (void) _updateFromProfileBackgroundColor
{
  if (_currentAttributes[MUInverseColorsAttributeName]
      && [_currentAttributes[MUCustomBackgroundColorAttributeName] intValue] == MUDefaultBackgroundColorTag)
  {
    _currentAttributes[NSForegroundColorAttributeName] = _profile.effectiveBackgroundColor;
  }
}

- (void) _updateFromProfileFont
{
  NSFont *newEffectiveFont;
  
  if (_currentAttributes[MUBoldFontAttributeName]
      && [[NSUserDefaults standardUserDefaults] boolForKey: MUPDisplayBrightAsBold])
  {
    newEffectiveFont = [_profile.effectiveFont boldFontWithRespectTo: _profile.effectiveFont];
  }
  else
    newEffectiveFont = _profile.effectiveFont;
  
  _currentAttributes[NSFontAttributeName] = newEffectiveFont;
}

- (void) _updateFromProfileTextColor
{
  if ([_currentAttributes[MUCustomForegroundColorAttributeName] intValue] == MUDefaultForegroundColorTag)
  {
    if (_currentAttributes[MUInverseColorsAttributeName])
      _currentAttributes[NSBackgroundColorAttributeName] = _profile.effectiveTextColor;
    else
      _currentAttributes[NSForegroundColorAttributeName] = _profile.effectiveTextColor;
  }
}

#pragma mark - Attribute manipulation

- (void) _removeAttribute: (NSString *) attribute
                 inString: (NSMutableAttributedString *) string
             fromLocation: (NSUInteger) startLocation
{
  [string removeAttribute: attribute
                    range: NSMakeRange (startLocation, string.length - startLocation)];
  [_currentAttributes removeObjectForKey: attribute];
}

- (void) _resetBackgroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self _setAttribute: MUCustomBackgroundColorAttributeName
              toValue: @(MUDefaultBackgroundColorTag)
             inString: string
         fromLocation: startLocation];
  if (_currentAttributes[MUInverseColorsAttributeName])
  {
    [self _setAttribute: NSForegroundColorAttributeName
                toValue: _profile.effectiveBackgroundColor
               inString: string
           fromLocation: startLocation];
  }
  else
    [self _removeAttribute: NSBackgroundColorAttributeName inString: string fromLocation: startLocation];
}

- (void) _resetBlinkInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  return;
}

- (void) _resetBoldInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self _removeAttribute: MUBoldFontAttributeName inString: string fromLocation: startLocation];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  if ([defaults boolForKey: MUPDisplayBrightAsBold])
  {
    [self _setAttribute: NSFontAttributeName
                toValue: [_currentAttributes[NSFontAttributeName] unboldFontWithRespectTo: _profile.effectiveFont]
               inString: string
           fromLocation: startLocation];
  }
  
  NSColor *targetColor;
  
  switch ([_currentAttributes[MUCustomForegroundColorAttributeName] intValue])
  {
    case MUANSIBlackColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
      break;
      
    case MUANSIRedColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
      break;
      
    case MUANSIGreenColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
      break;
      
    case MUANSIYellowColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
      break;
      
    case MUANSIBlueColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
      break;
      
    case MUANSIMagentaColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
      break;
      
    case MUANSICyanColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
      break;
      
    case MUANSIWhiteColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
      break;
      
    default:
      return;
  }
  
  [self _setAttribute: (_currentAttributes[MUInverseColorsAttributeName]
                        ? NSBackgroundColorAttributeName
                        : NSForegroundColorAttributeName)
              toValue: targetColor
             inString: string
         fromLocation: startLocation];
}

- (void) _resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self _setAttribute: MUCustomForegroundColorAttributeName
              toValue: @(MUDefaultForegroundColorTag)
             inString: string
         fromLocation: startLocation];
  [self _setAttribute: (_currentAttributes[MUInverseColorsAttributeName]
                        ? NSBackgroundColorAttributeName
                        : NSForegroundColorAttributeName)
              toValue: _profile.effectiveTextColor
             inString: string
         fromLocation: startLocation];
}

- (void) _resetHiddenTextInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  return;
}

- (void) _resetInverseInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  if (_currentAttributes[MUInverseColorsAttributeName])
  {
    [self _removeAttribute: MUInverseColorsAttributeName inString: string fromLocation: startLocation];
    
    NSColor *savedForegroundColor = _currentAttributes[NSForegroundColorAttributeName];
    
    [self _setAttribute: NSForegroundColorAttributeName
                toValue: _currentAttributes[NSBackgroundColorAttributeName]
               inString: string
           fromLocation: startLocation];
    
    if ([_currentAttributes[MUCustomBackgroundColorAttributeName] intValue] == MUDefaultBackgroundColorTag)
      [self _removeAttribute: NSBackgroundColorAttributeName inString: string fromLocation: startLocation];
    else
      [self _setAttribute: NSBackgroundColorAttributeName
                  toValue: savedForegroundColor
                 inString: string
             fromLocation: startLocation];
  }
}

- (void) _resetItalicInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  return;
}

- (void) _resetStrikethroughInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self _removeAttribute: NSStrikethroughStyleAttributeName inString: string fromLocation: startLocation];
}

- (void) _resetUnderlineInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self _removeAttribute: NSUnderlineStyleAttributeName inString: string fromLocation: startLocation];
}

- (void) _setAttribute: (NSString *) attribute
               toValue: (id) value
              inString: (NSMutableAttributedString *) string
          fromLocation: (NSUInteger) startLocation
{
  [string addAttribute: attribute
                 value: value
                 range: NSMakeRange (startLocation, string.length - startLocation)];
  _currentAttributes[attribute] = value;
}

- (void) _setAttributes: (NSDictionary *) attributes
               inString: (NSMutableAttributedString *) string
           fromLocation: (NSUInteger) startLocation
{
  for (NSString *key in attributes.allKeys)
  {
    [self _setAttribute: key
                toValue: [attributes valueForKey: key]
               inString: string
           fromLocation: startLocation];
  }
}

- (void) _setAttributesInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
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
        
        [self _setForegroundColor: targetColor
                   customColorTag: customColorTag
                         inString: string
                     fromLocation: startLocation];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        [self _setForegroundColor: [NSColor ANSI256ColorCubeColorForCode: colorCode]
                   customColorTag: MUANSI256FixedColorTag
                         inString: string
                     fromLocation: startLocation];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        [self _setForegroundColor: [NSColor ANSI256GrayscaleColorForCode: colorCode]
                   customColorTag: MUANSI256FixedColorTag
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
        
        [self _setBackgroundColor: targetColor
                   customColorTag: customColorTag
                         inString: string
                     fromLocation: startLocation];
      }
      else if (colorCode >= 16 && colorCode < 232)
      {
        [self _setBackgroundColor: [NSColor ANSI256ColorCubeColorForCode: colorCode]
                   customColorTag: MUANSI256FixedColorTag
                         inString: string
                     fromLocation: startLocation];
      }
      else if (colorCode >= 232 && colorCode < 256)
      {
        [self _setBackgroundColor: [NSColor ANSI256GrayscaleColorForCode: colorCode]
                   customColorTag: MUANSI256FixedColorTag
                         inString: string
                     fromLocation: startLocation];
      }
      
      return;
    }
  }
  
  for (NSString *code in codeComponents)
  {
    switch (code.intValue)
    {
      case MUANSIReset:
        [self _resetInverseInString: string fromLocation: startLocation];
        [self _resetHiddenTextInString: string fromLocation: startLocation];
        [self _resetBoldInString: string fromLocation: startLocation];
        [self _resetItalicInString: string fromLocation: startLocation];
        [self _resetForegroundInString: string fromLocation: startLocation];
        [self _resetBackgroundInString: string fromLocation: startLocation];
        [self _resetUnderlineInString: string fromLocation: startLocation];
        [self _resetStrikethroughInString: string fromLocation: startLocation];
        [self _resetBlinkInString: string fromLocation: startLocation];
        break;
        
      case MUANSIBoldOn:
        [self _setBoldInString: string fromLocation: startLocation];
        break;
        
      case MUANSIItalicsOn:
        break;
        
      case MUANSIUnderlineOn:
        [self _setAttribute: NSUnderlineStyleAttributeName
                    toValue: @(NSUnderlinePatternSolid | NSUnderlineStyleSingle)
                   inString: string
               fromLocation: startLocation];
        break;
        
      case MUANSISlowBlinkOn:
        break;
        
      case MUANSIRapidBlinkOn:
        break;
        
      case MUANSIInverseOn:
      {
        [self _setAttribute: MUInverseColorsAttributeName toValue: @YES inString: string fromLocation: startLocation];
        
        NSColor *savedForegroundColor = _currentAttributes[NSForegroundColorAttributeName];
        
        [self _setAttribute: NSForegroundColorAttributeName
                    toValue: (_currentAttributes[NSBackgroundColorAttributeName]
                              ? _currentAttributes[NSBackgroundColorAttributeName]
                              : _profile.effectiveBackgroundColor)
                   inString: string
               fromLocation: startLocation];
        [self _setAttribute: NSBackgroundColorAttributeName
                    toValue: savedForegroundColor
                   inString: string
               fromLocation: startLocation];

        break;
      }
        
      case MUANSIHiddenTextOn:
        break;
        
      case MUANSIStrikethroughOn:
      {
        [self _setAttribute: NSStrikethroughStyleAttributeName
                    toValue: @(NSUnderlinePatternSolid | NSUnderlineStyleSingle)
                   inString: string
               fromLocation: startLocation];
        break;
      }
        
      case MUANSIBoldOff:
        [self _resetBoldInString: string fromLocation: startLocation];
        break;
        
      case MUANSIItalicsOff:
        [self _resetItalicInString: string fromLocation: startLocation];
        
      case MUANSIUnderlineOff:
        [self _resetUnderlineInString: string fromLocation: startLocation];
        break;
        
      case MUANSIBlinkOff:
        [self _resetBlinkInString: string fromLocation: startLocation];
        
      case MUANSIInverseOff:
        [self _resetInverseInString: string fromLocation: startLocation];
        break;
        
      case MUANSIHiddenTextOff:
        [self _resetHiddenTextInString: string fromLocation: startLocation];
        
      case MUANSIStrikethroughOff:
        [self _resetStrikethroughInString: string fromLocation: startLocation];
        
      case MUANSIForegroundBlack:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIBlackColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundRed:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIRedColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundGreen:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIGreenColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundYellow:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIYellowColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundBlue:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIBlueColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundMagenta:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIMagentaColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundCyan:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSICyanColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundWhite:
      {
        NSColor *targetColor;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (_currentAttributes[MUBoldFontAttributeName])
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
        else
          targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
        
        [self _setForegroundColor: targetColor
                   customColorTag: MUANSIWhiteColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIForegroundDefault:
        [self _resetForegroundInString: string fromLocation: startLocation];
        break;
        
      case MUANSIBackgroundBlack:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]]
                   customColorTag: MUANSIBlackColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundRed:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]]
                   customColorTag: MUANSIRedColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundGreen:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]]
                   customColorTag: MUANSIGreenColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundYellow:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]]
                   customColorTag: MUANSIYellowColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundBlue:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]]
                   customColorTag: MUANSIBlueColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundMagenta:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]]
                   customColorTag: MUANSIMagentaColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundCyan:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]]
                   customColorTag: MUANSICyanColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundWhite:
      {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self _setBackgroundColor: [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]]
                   customColorTag: MUANSIWhiteColorTag
                         inString: string
                     fromLocation: startLocation];
        break;
      }
        
      case MUANSIBackgroundDefault:
        [self _resetBackgroundInString: string fromLocation: startLocation];
        break;
        
      default:
        NSLog (@"Received unhandled ANSI SGR command: %i", code.intValue);
        break;
    }
  }
}

- (void) _setBackgroundColor: (NSColor *) color
              customColorTag: (enum MUCustomColorTags) customColorTag
                    inString: (NSMutableAttributedString *) string
                fromLocation: (NSUInteger) startLocation
{
  [self _setAttribute: MUCustomBackgroundColorAttributeName
              toValue: @(customColorTag)
             inString: string
         fromLocation: startLocation];
  [self _setAttribute: (_currentAttributes[MUInverseColorsAttributeName]
                        ? NSForegroundColorAttributeName
                        : NSBackgroundColorAttributeName)
              toValue: color
             inString: string
         fromLocation: startLocation];
}

- (void) _setBoldInString: (NSMutableAttributedString *) string
             fromLocation: (NSUInteger) startLocation
{
  [self _setAttribute: MUBoldFontAttributeName toValue: @YES inString: string fromLocation: startLocation];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  if ([defaults boolForKey: MUPDisplayBrightAsBold])
  {
    [self _setAttribute: NSFontAttributeName
              toValue: [_currentAttributes[NSFontAttributeName] boldFontWithRespectTo: _profile.effectiveFont]
             inString: string
         fromLocation: startLocation];
  }
  
  NSColor *targetColor;
  
  switch ([_currentAttributes[MUCustomForegroundColorAttributeName] intValue])
  {
    case MUANSIBlackColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
      break;
      
    case MUANSIRedColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
      break;
      
    case MUANSIGreenColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
      break;
      
    case MUANSIYellowColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
      break;
      
    case MUANSIBlueColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
      break;
      
    case MUANSIMagentaColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
      break;
      
    case MUANSICyanColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
      break;
      
    case MUANSIWhiteColorTag:
      targetColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
      break;
      
    default:
      return;
  }
  
  [self _setAttribute: (_currentAttributes[MUInverseColorsAttributeName]
                        ? NSBackgroundColorAttributeName
                        : NSForegroundColorAttributeName)
              toValue: targetColor
             inString: string
         fromLocation: startLocation];
}

- (void) _setForegroundColor: (NSColor *) color
              customColorTag: (enum MUCustomColorTags) customColorTag
                    inString: (NSMutableAttributedString *) string
                fromLocation: (NSUInteger) startLocation
{
  [self _setAttribute: MUCustomForegroundColorAttributeName
              toValue: @(customColorTag)
             inString: string
         fromLocation: startLocation];
  
  [self _setAttribute: (_currentAttributes[MUInverseColorsAttributeName]
                        ? NSBackgroundColorAttributeName
                        : NSForegroundColorAttributeName)
              toValue: color
             inString: string
         fromLocation: startLocation];
}

@end
