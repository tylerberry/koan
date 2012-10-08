//
// MUANSIFormattingFilter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUANSIFormattingFilter.h"
#import "NSFont (Traits).h"

@interface MUANSIFormattingFilter ()
{
  BOOL inCode;
  NSString *ansiCode;
  NSMutableDictionary *currentAttributes;
}

@property (strong, nonatomic) MUProfile *profile;

- (void) applyCode: (unichar) code
          toString: (NSMutableAttributedString *) mutableString
        atLocation: (NSUInteger) startLocation;
- (NSArray *) attributeNamesForANSICode;
- (NSArray *) attributeValuesForANSICodeInString: (NSAttributedString *) string atLocation: (NSUInteger) startLocation;
- (BOOL) extractCode: (NSMutableAttributedString *) editString;
- (NSFont *) fontInString: (NSAttributedString *) string atLocation: (NSUInteger) location;
- (NSUInteger) scanUpToCodeInString: (NSString *) string;
- (NSUInteger) scanThroughEndOfCodeAt: (NSUInteger) index inString: (NSString *) string;
- (NSFont *) setTrait: (NSFontTraitMask) trait onFont: (NSFont *) font;
- (void) updateFromProfileFont;
- (void) updateFromProfileTextColor;

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
- (void) setAttributesInString: (NSMutableAttributedString *) string atLocation: (NSUInteger) startLocation;

@end

#pragma mark -

@implementation MUANSIFormattingFilter

@synthesize delegate, profile;

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
  
  ansiCode = nil;
  inCode = NO;
  profile = newProfile;
  delegate = newDelegate;
  
  currentAttributes = [[NSMutableDictionary alloc] init];
  [currentAttributes setValue: profile.effectiveFont forKey: NSFontAttributeName];
  [currentAttributes setValue: profile.effectiveTextColor forKey: NSForegroundColorAttributeName];
  
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
  if (object == profile)
  {
    if ([keyPath isEqualToString: @"effectiveFont"])
    {
      [self updateFromProfileFont];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveTextColor"])
    {
      [self updateFromProfileTextColor];
      return;
    }
  }
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

- (NSAttributedString *) filter: (NSAttributedString *) attributedString
{
  NSMutableAttributedString *editString = [attributedString mutableCopy];
  
  [self setAttributes: currentAttributes onString: editString fromLocation: 0];
  
  while ([self extractCode: editString])
    ;
  
  return editString;
}

#pragma mark - Private methods

- (void) applyCode: (unichar) code
          toString: (NSMutableAttributedString *) mutableString
        atLocation: (NSUInteger) startLocation
{
  switch (code)
  {
    case MUANSISelectGraphicRendition:
      [self setAttributesInString: mutableString atLocation: startLocation];
      return;
      
    case MUANSIEraseData:
      if (ansiCode.length == 3)
      {
        if ([ansiCode characterAtIndex: 2] == '1' || [ansiCode characterAtIndex: 2] == '2')
          [mutableString deleteCharactersInRange: NSMakeRange (0, startLocation)];
        
        if ([ansiCode characterAtIndex: 2] == '2')
        {
          if ([self.delegate respondsToSelector: @selector (clearScreen)])
            [self.delegate clearScreen];
        }
      }
      return;
      
    default:
      return;
  }
}

- (NSArray *) attributeNamesForANSICode
{
  NSArray *codeComponents = [[ansiCode substringFromIndex: 2] componentsSeparatedByString: @";"];
  NSMutableArray *names = [NSMutableArray arrayWithCapacity: codeComponents.count];
  
  if (codeComponents.count == 3
      && [codeComponents[1] intValue] == 5)
  {
    if ([codeComponents[0] intValue] == MUANSIBackground256)
    {
      [names addObject: NSBackgroundColorAttributeName];
      return names;
    }
    else if ([codeComponents[0] intValue] == MUANSIForeground256)
    {
      [names addObject: MUCustomColorAttributeName];
      [names addObject: NSForegroundColorAttributeName];
      return names;
    }
  }
  
  for (NSString *code in codeComponents)
  {
    switch ([code intValue])
    {
      case MUANSIBackgroundBlack:
      case MUANSIBackgroundBlue:
      case MUANSIBackgroundCyan:
      case MUANSIBackgroundDefault:
      case MUANSIBackgroundGreen:
      case MUANSIBackgroundMagenta:
      case MUANSIBackgroundRed:
      case MUANSIBackgroundWhite:
      case MUANSIBackgroundYellow:
        [names addObject: NSBackgroundColorAttributeName];
        break;
        
      case MUANSIForegroundBlack:
      case MUANSIForegroundBlue:
      case MUANSIForegroundCyan:
      case MUANSIForegroundDefault:
      case MUANSIForegroundGreen:
      case MUANSIForegroundMagenta:
      case MUANSIForegroundRed:
      case MUANSIForegroundWhite:
      case MUANSIForegroundYellow:
        [names addObject: MUCustomColorAttributeName];
        [names addObject: NSForegroundColorAttributeName];
        break;
        
      case MUANSIBoldOn:
      case MUANSIBoldOff:
        [names addObject: MUBoldFontAttributeName];
        [names addObject: NSFontAttributeName];
        break;
        
      case MUANSIUnderlineOn:
      case MUANSIUnderlineOff:
        [names addObject: NSUnderlineStyleAttributeName];
        break;
        
      default:
        [names addObject: [NSNull null]];
        break;
    }
  }
  
  return names;
}

- (NSArray *) attributeValuesForANSICodeInString: (NSAttributedString *) string atLocation: (NSUInteger) location
{
  NSArray *codeComponents = [[ansiCode substringFromIndex: 2] componentsSeparatedByString: @";"];
  NSMutableArray *values = [NSMutableArray arrayWithCapacity: codeComponents.count];
  
  if (codeComponents.count == 3
      && [codeComponents[1] intValue] == 5)
  {
    if ([codeComponents[0] intValue] == MUANSIBackground256
        || [codeComponents[0] intValue] == MUANSIForeground256)
    {
      int value = [codeComponents[2] intValue];
      
      if ([codeComponents[0] intValue] == MUANSIForeground256)
      {
        if (value >= 0 && value < 256)
          [values addObject: @YES];
        else
          [values addObject: [NSNull null]];
      }
      
      if (value >= 0 && value < 16)
      {
        switch (value)
        {
          case MUANSI256Black:
          case MUANSI256BrightBlack:
            [values addObject: [NSColor darkGrayColor]];
            break;
            
          case MUANSI256Red:
          case MUANSI256BrightRed:
            [values addObject: [NSColor redColor]];
            break;
            
          case MUANSI256Green:
          case MUANSI256BrightGreen:
            [values addObject: [NSColor greenColor]];
            break;
            
          case MUANSI256Yellow:
          case MUANSI256BrightYellow:
            [values addObject: [NSColor yellowColor]];
            break;
            
          case MUANSI256Blue:
          case MUANSI256BrightBlue:
            [values addObject: [NSColor blueColor]];
            break;
            
          case MUANSI256Magenta:
          case MUANSI256BrightMagenta:
            [values addObject: [NSColor magentaColor]];
            break;
            
          case MUANSI256Cyan:
          case MUANSI256BrightCyan:
            [values addObject: [NSColor cyanColor]];
            break;
            
          case MUANSI256White:
          case MUANSI256BrightWhite:
            [values addObject: [NSColor whiteColor]];
            break;
        }
      }
      else if (value > 15 && value < 232)
      {
        int adjustedValue = value - 16;
        int red = adjustedValue / 36;
        int green = (adjustedValue % 36) / 6;
        int blue = (adjustedValue % 36) % 6;
        
        NSColor *cubeColor = [NSColor colorWithCalibratedRed: 1. / 6. * red
                                                       green: 1. / 6. * green
                                                        blue: 1. / 6. * blue
                                                       alpha: 1.0];
        [values addObject: cubeColor];
      }
      else if (value > 231 && value < 256)
      {
        int adjustedValue = value - 231;
        
        NSColor *grayscaleColor = [NSColor colorWithCalibratedWhite: 1. / 25. * adjustedValue
                                                              alpha: 1.0];
        [values addObject: grayscaleColor];
      }
      
      return values;
    }
  }
  
  for (NSString *code in codeComponents)
  {
    switch (code.intValue)
    {
      case MUANSIForegroundBlack:
        [values addObject: @YES];
      case MUANSIBackgroundBlack:
        [values addObject: [NSColor darkGrayColor]];
        break;
        
      case MUANSIForegroundBlue:
        [values addObject: @YES];
      case MUANSIBackgroundBlue:
        [values addObject: [NSColor blueColor]];
        break;
        
      case MUANSIForegroundCyan:
        [values addObject: @YES];
      case MUANSIBackgroundCyan:
        [values addObject: [NSColor cyanColor]];
        break;
        
      case MUANSIForegroundDefault:
        [values addObject: [NSNull null]];
        [values addObject: profile.effectiveTextColor];
        break;
        
      case MUANSIBackgroundDefault:
        [values addObject: [NSNull null]];
        break;
        
      case MUANSIForegroundGreen:
        [values addObject: @YES];
      case MUANSIBackgroundGreen:
        [values addObject: [NSColor greenColor]];
        break;
        
      case MUANSIForegroundMagenta:
        [values addObject: @YES];
      case MUANSIBackgroundMagenta:
        [values addObject: [NSColor magentaColor]];
        break;
        
      case MUANSIForegroundRed:
        [values addObject: @YES];
      case MUANSIBackgroundRed:
        [values addObject: [NSColor redColor]];
        break;
        
      case MUANSIForegroundWhite:
        [values addObject: @YES];
      case MUANSIBackgroundWhite:
        [values addObject: [NSColor whiteColor]];
        break;
        
      case MUANSIForegroundYellow:
        [values addObject: @YES];
      case MUANSIBackgroundYellow:
        [values addObject: [NSColor yellowColor]];
        break;
        
      case MUANSIBoldOn:
        [values addObject: @YES];
        [values addObject: [currentAttributes[NSFontAttributeName] boldFontWithRespectTo: profile.effectiveFont]];
        break;
        
      case MUANSIBoldOff:
        [values addObject: [NSNull null]];
        [values addObject: [currentAttributes[NSFontAttributeName] unboldFontWithRespectTo: profile.effectiveFont]];
        break;
        
      case MUANSIUnderlineOn:
        [values addObject: @(NSSingleUnderlineStyle)];
        break;
        
      case MUANSIUnderlineOff:
        [values addObject: [NSNull null]];
        break;
        
      default:
        [values addObject: [NSNull null]];
        break;
    }
  }
  return values;
}

- (BOOL) extractCode: (NSMutableAttributedString *) editString
{
  NSRange codeRange;
  
  if (!inCode)
  {
    codeRange.location = [self scanUpToCodeInString: editString.string];
    
    ansiCode = @"";
  }
  else
    codeRange.location = 0;
  
  if (inCode || codeRange.location != NSNotFound)
  {
    inCode = YES;
    codeRange.length = [self scanThroughEndOfCodeAt: codeRange.location
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
      inCode = NO;
      [editString deleteCharactersInRange: codeRange];
      [self applyCode: code toString: editString atLocation: codeRange.location];
      return YES;
    }
  }
  
  return NO;
}

- (NSFont *) fontInString: (NSAttributedString *) string atLocation: (NSUInteger) location
{
  return [string attribute: NSFontAttributeName atIndex: location effectiveRange: NULL];
}

- (NSUInteger) scanUpToCodeInString: (NSString *) string
{
  NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString: @"\x1B"];
  NSRange stopRange = [string rangeOfCharacterFromSet: stopSet];
  NSScanner *scanner = [NSScanner scannerWithString: string];
  [scanner setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @""]];
  
  if (stopRange.location == NSNotFound)
    return NSNotFound;
  
  while ([scanner scanUpToCharactersFromSet: stopSet intoString: nil])
    ;
  return scanner.scanLocation;
}

- (NSUInteger) scanThroughEndOfCodeAt: (NSUInteger) codeIndex inString: (NSString *) string
{
  NSScanner *scanner = [NSScanner scannerWithString: string];
  [scanner setScanLocation: codeIndex];
  [scanner setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @""]];
  
  NSCharacterSet *resumeSet = [NSCharacterSet characterSetWithCharactersInString: @"ABCDEFGHJKSTfhlmnsu"];
  
  NSString *charactersFromThisScan = @"";
  [scanner scanUpToCharactersFromSet: resumeSet intoString: &charactersFromThisScan];
  
  NSString *newAnsiCode = [[NSString alloc] initWithFormat: @"%@%@", ansiCode, charactersFromThisScan];
  ansiCode = newAnsiCode;
  
  if (scanner.scanLocation == string.length)
    return NSNotFound;
  else
    return charactersFromThisScan.length + 1;
}

- (NSFont *) setTrait: (NSFontTraitMask) trait onFont: (NSFont *) font
{
  return [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: trait];
}

#pragma mark - Attribute manipulation

- (void) removeAttribute: (NSString *) attribute
                inString: (NSMutableAttributedString *) string
            fromLocation: (NSUInteger) startLocation
{
  [string removeAttribute: attribute
                    range: NSMakeRange (startLocation, string.length - startLocation)];
  [currentAttributes removeObjectForKey: attribute];
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
             toValue: profile.effectiveFont
            inString: string
        fromLocation: startLocation];
}

- (void) resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self setAttribute: NSForegroundColorAttributeName
             toValue: profile.effectiveTextColor
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
  currentAttributes[attribute] = value;
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

- (void) setAttributesInString: (NSMutableAttributedString *) string atLocation: (NSUInteger) startLocation
{
  if (string.length <= startLocation)
    return;
  
  if ([[ansiCode substringFromIndex: 2] intValue] == 0)
    [self resetAllAttributesInString: string fromLocation: startLocation];
  
  NSArray *attributeNames = [self attributeNamesForANSICode];
  if (!attributeNames)
    return;
  
  NSArray *attributeValues = [self attributeValuesForANSICodeInString: string atLocation: startLocation];
  if (!attributeValues)
    return;
  
  if (attributeNames.count != attributeValues.count)
    @throw [NSException exceptionWithName: @"MUANSIException"
                                   reason: @"attributeNames.count != attributeValues.count"
                                 userInfo: nil];
  
  for (NSUInteger i = 0; i < attributeNames.count; i++)
  {
    id attributeName = attributeNames[i];
    id attributeValue = attributeValues[i];
    
    if (attributeName == [NSNull null])
      continue;
    
    if (attributeValue != [NSNull null])
      [self setAttribute: attributeName toValue: attributeValue inString: string fromLocation: startLocation];
    else
    {
      if ([attributeName isEqualToString: NSForegroundColorAttributeName])
        [self resetForegroundInString: string fromLocation: startLocation];
      else if ([attributeName isEqualToString: NSBackgroundColorAttributeName])
        [self resetBackgroundInString: string fromLocation: startLocation];
      else if ([attributeName isEqualToString: NSUnderlineStyleAttributeName])
        [self resetUnderlineInString: string fromLocation: startLocation];
      else if ([attributeName isEqualToString: MUBoldFontAttributeName])
        [self resetBoldInString: string fromLocation: startLocation];
      else if ([attributeName isEqualToString: MUCustomColorAttributeName])
        [self resetCustomColorInString: string fromLocation: startLocation];
      else
        @throw [NSException exceptionWithName: @"MUANSIException"
                                       reason: @"attributeValue was an invalid [NSNull null]"
                                     userInfo: nil];
    }
  }
}

- (void) updateFromProfileFont
{
  NSFont *newEffectiveFont;
  
  if (currentAttributes[MUBoldFontAttributeName])
    newEffectiveFont = [profile.effectiveFont boldFontWithRespectTo: profile.effectiveFont];
  else
    newEffectiveFont = profile.effectiveFont;
  
  currentAttributes[NSFontAttributeName] = newEffectiveFont;
}

- (void) updateFromProfileTextColor
{
  if (!currentAttributes[MUCustomColorAttributeName])
    currentAttributes[NSForegroundColorAttributeName] = profile.effectiveTextColor;
}

@end
