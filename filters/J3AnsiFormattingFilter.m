//
// J3AnsiFormattingFilter.m
//
// Copyright (c) 2004, 2005 3James Software
//

#import "J3AnsiFormattingFilter.h"
#import "MUFormatting.h"

@interface J3AnsiFormattingFilter (Private)

- (NSString *) attributeNameForAnsiCode;
- (id) attributeValueForAnsiCode;
- (BOOL) extractCode:(NSMutableAttributedString *)editString;
- (void) resetAllAttributesInString:(NSMutableAttributedString *)string fromLocation:(int)location;
- (void) resetBackgroundInString:(NSMutableAttributedString *)string fromLocation:(int)location;
- (void) resetForegroundInString:(NSMutableAttributedString *)string fromLocation:(int)location;
- (void) setAttribute:(NSString *)attribute toValue:(id)value inString:(NSMutableAttributedString *)string fromLocation:(int)location;
- (void) setAttributes:(NSDictionary *)attributes onString:(NSMutableAttributedString *)string fromLocation:(int)location;
- (int) scanUpToCodeInString:(NSString *)string;
- (int) scanThruEndOfCodeAt:(int)index inString:(NSString *)string;
- (void) setAttributesInString:(NSMutableAttributedString *)string atPosition:(int)start;

@end

@implementation J3AnsiFormattingFilter
+ (J3Filter *) filterWithFormatting:(NSObject <MUFormatting> *)format;
{
  return [[[self alloc] initWithFormatting:format] autorelease];
}


- (NSAttributedString *) filter:(NSAttributedString *)string;
{
  NSMutableAttributedString *editString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
  
  [self setAttributes:currentAttributes onString:editString fromLocation:0];
  
  while ([self extractCode:editString])
    ;
  
  [editString autorelease];
  return editString;
}

- (id) initWithFormatting:(NSObject <MUFormatting> *)format;
{
  if (!(self = [super init]))
    return nil;
  [self at:&currentAttributes put:[NSMutableDictionary dictionary]];
  [self at:&formatting put:format];
  return self; 
}

- (id) init;
{
  return [self initWithFormatting:[MUFormatting formattingForTesting]];
}

@end

@implementation J3AnsiFormattingFilter (Private)

- (NSString *) attributeNameForAnsiCode;
{
  switch ([[ansiCode substringFromIndex:2] intValue]) 
  {
    case J3AnsiBackgroundBlack:
    case J3AnsiBackgroundBlue:
    case J3AnsiBackgroundCyan:
    case J3AnsiBackgroundDefault:
    case J3AnsiBackgroundGreen:
    case J3AnsiBackgroundMagenta:
    case J3AnsiBackgroundRed:
    case J3AnsiBackgroundWhite:
    case J3AnsiBackgroundYellow:
      return NSBackgroundColorAttributeName;
      break;
    case J3AnsiForegroundBlack:
    case J3AnsiForegroundBlue:
    case J3AnsiForegroundCyan:
    case J3AnsiForegroundDefault:
    case J3AnsiForegroundGreen:
    case J3AnsiForegroundMagenta:
    case J3AnsiForegroundRed:
    case J3AnsiForegroundWhite:
    case J3AnsiForegroundYellow:
      return NSForegroundColorAttributeName;
      break;
  }
return nil;
}

- (id) attributeValueForAnsiCode;
{
  switch ([[ansiCode substringFromIndex:2] intValue]) 
  {
    case J3AnsiBackgroundBlack: 
    case J3AnsiForegroundBlack: 
      return [NSColor blackColor];
      break;
      
    case J3AnsiBackgroundBlue:
    case J3AnsiForegroundBlue:
      return [NSColor blueColor];
      break;

    case J3AnsiBackgroundCyan:
    case J3AnsiForegroundCyan:
      return [NSColor cyanColor];
      break;
      
    case J3AnsiBackgroundDefault:
      return [formatting background];
      break;

    case J3AnsiForegroundDefault:
      return [formatting foreground];
      break;
      
    case J3AnsiBackgroundGreen:
    case J3AnsiForegroundGreen:
      return [NSColor greenColor];
      break;
      
    case J3AnsiBackgroundMagenta:
    case J3AnsiForegroundMagenta:
      return [NSColor magentaColor];
      break;
      
    case J3AnsiBackgroundRed:
    case J3AnsiForegroundRed:
      return [NSColor redColor];
      break;
      
    case J3AnsiBackgroundWhite:
    case J3AnsiForegroundWhite:
      return [NSColor whiteColor];
      break;
      
    case J3AnsiBackgroundYellow:
    case J3AnsiForegroundYellow:
      return [NSColor yellowColor];
      break;    
  }
  return nil;
}

- (BOOL) extractCode:(NSMutableAttributedString *)editString
{
  NSRange codeRange;
  
  codeRange.location = [self scanUpToCodeInString:[editString string]];
  
  if (codeRange.location != NSNotFound)
  {
    codeRange.length = [self scanThruEndOfCodeAt:codeRange.location
                                        inString:[editString string]];
    
    if (codeRange.location < [editString length])
    {
      [editString deleteCharactersInRange:codeRange];
      [self setAttributesInString:editString atPosition:codeRange.location];
      return YES;
    }
  }

  return NO;
}

- (void) resetAllAttributesInString:(NSMutableAttributedString *)string fromLocation:(int)location;
{
  [self resetBackgroundInString:string fromLocation:location];
  [self resetForegroundInString:string fromLocation:location];
}

- (void) resetBackgroundInString:(NSMutableAttributedString *)string fromLocation:(int)location;
{
  [self setAttribute:NSBackgroundColorAttributeName toValue:[formatting background] inString:string fromLocation:location];
}

- (void) resetForegroundInString:(NSMutableAttributedString *)string fromLocation:(int)location;
{
  [self setAttribute:NSForegroundColorAttributeName toValue:[formatting foreground] inString:string fromLocation:location];
}

- (void) setAttribute:(NSString *)attribute toValue:(id)value inString:(NSMutableAttributedString *)string fromLocation:(int)location;
{
  [string addAttribute:attribute value:value range:NSMakeRange (location,[string length] - location)];
  [currentAttributes setObject:value forKey:attribute];
}

- (void) setAttributes:(NSDictionary *)attributes onString:(NSMutableAttributedString *)string fromLocation:(int)location;
{
  NSDictionary * attributeCopy = [attributes copy];
  NSEnumerator * keyEnumerator = [attributeCopy keyEnumerator];
  NSString * key;
  
  while ((key = [keyEnumerator nextObject]))
    [self setAttribute:key toValue:[attributeCopy valueForKey:key] inString:string fromLocation:location];
}

- (int) scanUpToCodeInString:(NSString *)string
{
  NSCharacterSet *stopSet = 
    [NSCharacterSet characterSetWithCharactersInString:@"\x1B"];
  NSRange stopRange = [string rangeOfCharacterFromSet:stopSet];
  NSScanner *scanner = [NSScanner scannerWithString:string];
  [scanner setCharactersToBeSkipped:
    [NSCharacterSet characterSetWithCharactersInString:@""]];

  if (stopRange.location == NSNotFound)
    return NSNotFound;
  
  while ([scanner scanUpToCharactersFromSet:stopSet intoString:nil])
    ;
  return [scanner scanLocation];
}

- (int) scanThruEndOfCodeAt:(int)index inString:(NSString *)string
{
  NSScanner *scanner = [NSScanner scannerWithString:string];
  [scanner setScanLocation:index];
  [scanner setCharactersToBeSkipped:
    [NSCharacterSet characterSetWithCharactersInString:@""]];

  NSCharacterSet *resumeSet = 
    [NSCharacterSet characterSetWithCharactersInString:
      @"m"];

  //TODO: Figure out how to do this with a nil intoString: parameter
  //like I do above with scanUpToCodeInString:
  ansiCode = @"";
  [scanner scanUpToCharactersFromSet:resumeSet intoString:&ansiCode];
  return [ansiCode length] + 1;
}

- (void) setAttributesInString:(NSMutableAttributedString *)string atPosition:(int)start;
{
  NSString * attributeName = nil;
  id attributeValue = nil;

  if ([[ansiCode substringFromIndex:2] intValue] == 0)
    [self resetAllAttributesInString:string fromLocation:start];
  
  attributeName = [self attributeNameForAnsiCode];
  if (!attributeName)
    return;

  attributeValue = [self attributeValueForAnsiCode];
  if (attributeValue)
    [self setAttribute:attributeName toValue:attributeValue inString:string fromLocation:start];
  else if ([attributeName isEqualToString:NSForegroundColorAttributeName])
    [self resetForegroundInString:string fromLocation:start];
  else if ([attributeName isEqualToString:NSBackgroundColorAttributeName])
    [self resetBackgroundInString:string fromLocation:start];
  else
    [string removeAttribute:attributeName range:NSMakeRange (start, [string length] - start)];
}

@end
