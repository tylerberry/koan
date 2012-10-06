//
// MUANSIFormattingFilter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUANSIFormattingFilter.h"
#import "MUFormatter.h"
#import "NSFont (Traits).h"

@interface MUANSIFormattingFilter ()
{
  BOOL inCode;
  NSString *ansiCode;
  NSObject <MUFormatter> *formatter;
  NSMutableDictionary *currentAttributes;
}

- (NSArray *) attributeNamesForANSICode;
- (NSArray *) attributeValuesForANSICodeInString: (NSAttributedString *) string atLocation: (NSUInteger) startLocation;
- (BOOL) extractCode: (NSMutableAttributedString *) editString;
- (NSFont *) fontInString: (NSAttributedString *) string atLocation: (NSUInteger) location;
- (NSFont *) makeFontBold: (NSFont *) font;
- (NSFont *) makeFontUnbold: (NSFont *) font;
- (void) resetAllAttributesInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetBackgroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetFontInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) resetUnderlineInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) setAttribute: (NSString *) attribute toValue: (id) value inString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (void) setAttributes: (NSDictionary *) attributes onString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation;
- (NSUInteger) scanUpToCodeInString: (NSString *) string;
- (NSUInteger) scanThroughEndOfCodeAt: (NSUInteger) index inString: (NSString *) string;
- (void) setAttributesInString: (NSMutableAttributedString *) string atLocation: (NSUInteger) startLocation;
- (NSFont *) setTrait: (NSFontTraitMask) trait onFont: (NSFont *) font;

@end

#pragma mark -

@implementation MUANSIFormattingFilter

+ (MUFilter *) filterWithFormatter: (NSObject <MUFormatter> *) newFormatter
{
  return [[self alloc] initWithFormatter: newFormatter];
}

- (id) initWithFormatter: (NSObject <MUFormatter> *) newFormatter
{
  if (!newFormatter)
    return nil;
  
  if (!(self = [super init]))
    return nil;
  
  ansiCode = nil;
  inCode = NO;
  formatter = newFormatter;
  currentAttributes = [[NSMutableDictionary alloc] init];
  [currentAttributes setValue: [formatter font] forKey: NSFontAttributeName];
  
  return self;
}

- (id) init
{
  return [self initWithFormatter: [MUFormatter formatterForTesting]];
}

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  NSMutableAttributedString *editString = [string mutableCopy];
  
  [self setAttributes: currentAttributes onString: editString fromLocation: 0];
  
  while ([self extractCode: editString])
    ;
  
  return editString;
}

#pragma mark - Private methods

- (NSArray *) attributeNamesForANSICode
{
  NSArray *codeComponents = [[ansiCode substringFromIndex: 2] componentsSeparatedByString: @";"];
  NSMutableArray *names = [NSMutableArray arrayWithCapacity: [codeComponents count]];
  
  if ([codeComponents count] == 3
      && [[codeComponents objectAtIndex: 1] intValue] == 5)
  {
    if ([[codeComponents objectAtIndex: 0] intValue] == MUANSIBackground256)
    {
      [names addObject: NSBackgroundColorAttributeName];
      return names;
    }
    else if ([[codeComponents objectAtIndex: 0] intValue] == MUANSIForeground256)
    {
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
        [names addObject: NSForegroundColorAttributeName];
        break;
        
      case MUANSIBoldOn:
      case MUANSIBoldOff:
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
      && [[codeComponents objectAtIndex: 1] intValue] == 5)
  {
    if ([[codeComponents objectAtIndex: 0] intValue] == MUANSIBackground256
        || [[codeComponents objectAtIndex: 0] intValue] == MUANSIForeground256)
    {
      int value = [[codeComponents objectAtIndex: 2] intValue];
      
      if (value < 16)
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
    switch ([code intValue])
    {
      case MUANSIBackgroundBlack:  
      case MUANSIForegroundBlack:  
        [values addObject: [NSColor darkGrayColor]];
        break;
        
      case MUANSIBackgroundBlue:
      case MUANSIForegroundBlue:
        [values addObject: [NSColor blueColor]];
        break;
        
      case MUANSIBackgroundCyan:
      case MUANSIForegroundCyan:
        [values addObject: [NSColor cyanColor]];
        break;
        
      case MUANSIBackgroundDefault:
        [values addObject: formatter.backgroundColor];
        break;
        
      case MUANSIForegroundDefault:
        [values addObject: formatter.foregroundColor];
        break;
        
      case MUANSIBackgroundGreen:
      case MUANSIForegroundGreen:
        [values addObject: [NSColor greenColor]];
        break;
        
      case MUANSIBackgroundMagenta:
      case MUANSIForegroundMagenta:
        [values addObject: [NSColor magentaColor]];
        break;
        
      case MUANSIBackgroundRed:
      case MUANSIForegroundRed:
        [values addObject: [NSColor redColor]];
        break;
        
      case MUANSIBackgroundWhite:
      case MUANSIForegroundWhite:
        [values addObject: [NSColor whiteColor]];
        break;
        
      case MUANSIBackgroundYellow:
      case MUANSIForegroundYellow:
        [values addObject: [NSColor yellowColor]];
        break;    
        
      case MUANSIBoldOn:
        [values addObject: [self makeFontBold: [self fontInString: string atLocation: location]]];
        break;
        
      case MUANSIBoldOff:
        [values addObject: [self makeFontUnbold: [self fontInString: string atLocation: location]]];
        break;
        
      case MUANSIUnderlineOn:
        [values addObject: [NSNumber numberWithInt: NSSingleUnderlineStyle]];
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
      inCode = NO;
      [editString deleteCharactersInRange: codeRange];
      [self setAttributesInString: editString atLocation: codeRange.location];
      return YES;
    }
  }
  
  return NO;
}

- (NSFont *) fontInString: (NSAttributedString *) string atLocation: (NSUInteger) location
{
  return [string attribute: NSFontAttributeName atIndex: location effectiveRange: NULL];
}

- (NSFont *) makeFontBold: (NSFont *) font
{  
  if (formatter.font.isBold)
    return [font fontWithTrait: NSUnboldFontMask];
  else
    return [font fontWithTrait: NSBoldFontMask];
}

- (NSFont *) makeFontUnbold: (NSFont *) font
{
  if (formatter.font.isBold)
    return [font fontWithTrait: NSBoldFontMask];
  else
    return [font fontWithTrait: NSUnboldFontMask];
}

- (void) resetAllAttributesInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self resetBackgroundInString: string fromLocation: startLocation];
  [self resetForegroundInString: string fromLocation: startLocation];
  [self resetFontInString: string fromLocation: startLocation];
  [self resetUnderlineInString: string fromLocation: startLocation];
}

- (void) resetBackgroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self setAttribute: NSBackgroundColorAttributeName
             toValue: formatter.backgroundColor
            inString: string
        fromLocation: startLocation];
}

- (void) resetFontInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self setAttribute: NSFontAttributeName
             toValue: formatter.font
            inString: string
        fromLocation: startLocation];
}

- (void) resetForegroundInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [self setAttribute: NSForegroundColorAttributeName
             toValue: formatter.foregroundColor
            inString: string
        fromLocation: startLocation];
}

- (void) resetUnderlineInString: (NSMutableAttributedString *) string fromLocation: (NSUInteger) startLocation
{
  [string removeAttribute: NSUnderlineStyleAttributeName
                    range: NSMakeRange (startLocation, string.length - startLocation)];
}

- (void) setAttribute: (NSString *) attribute
              toValue: (id) value
             inString: (NSMutableAttributedString *) string
         fromLocation: (NSUInteger) startLocation
{
  [string addAttribute: attribute
                 value: value
                 range: NSMakeRange (startLocation, string.length - startLocation)];
  [currentAttributes setObject: value forKey: attribute];
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
  
  NSCharacterSet *resumeSet = [NSCharacterSet characterSetWithCharactersInString: @"m"];
  
  NSString *charactersFromThisScan = @"";
  [scanner scanUpToCharactersFromSet: resumeSet intoString: &charactersFromThisScan];
  
  NSString *newAnsiCode = [[NSString alloc] initWithFormat: @"%@%@", ansiCode, charactersFromThisScan];
  ansiCode = newAnsiCode;
  
  if (scanner.scanLocation == string.length)
    return NSNotFound;
  else
    return charactersFromThisScan.length + 1;
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
    id attributeName = [attributeNames objectAtIndex: i];
    id attributeValue = [attributeValues objectAtIndex: i];
    
    if (attributeName == [NSNull null])
      continue;
    
    if (attributeValue != [NSNull null])
      [self setAttribute: attributeName toValue: attributeValue inString: string fromLocation: startLocation];
    else if ([attributeName isEqualToString: NSForegroundColorAttributeName])
      [self resetForegroundInString: string fromLocation: startLocation];
    else if ([attributeName isEqualToString: NSBackgroundColorAttributeName])
      [self resetBackgroundInString: string fromLocation: startLocation];
    else if ([attributeName isEqualToString: NSUnderlineStyleAttributeName])
      [self resetUnderlineInString: string fromLocation: startLocation];
    else
      @throw [NSException exceptionWithName: @"MUANSIException"
                                     reason: @"attributeValue was an invalid [NSNull null]"
                                   userInfo: nil];
  }
}

- (NSFont *) setTrait: (NSFontTraitMask) trait onFont: (NSFont *) font
{
  return [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: trait];
}

@end
