//
// MUNaiveURLFilter.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUNaiveURLFilter.h"

@interface MUNaiveURLFilter ()

- (void) linkifyURLs: (NSMutableAttributedString *) editString;
- (NSURL *) normalizedURLForString: (NSString *) string;

@end

#pragma mark -

@implementation MUNaiveURLFilter

+ (MUFilter *) filter
{
  return [[self alloc] init];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSMutableAttributedString *mutableString = [attributedString mutableCopy];
  
  [self linkifyURLs: mutableString];
  
  return mutableString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return [self filterCompleteLine: attributedString];
}

#pragma mark - Private methods

- (void) linkifyURLs: (NSMutableAttributedString *) editString
{
  NSString *sourceString = editString.string;
  NSScanner *scanner = [NSScanner scannerWithString: sourceString];
  NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSCharacterSet *nonwhitespace = whitespace.invertedSet;
  NSCharacterSet *skips = [NSCharacterSet characterSetWithCharactersInString: @",.!?()[]{}<>'\""];
  
  while (!scanner.isAtEnd)
  {
    NSString *scannedString;
    NSRange scannedRange;
    NSURL *foundURL;
    NSDictionary *linkAttributes;
    NSUInteger skipScanLocation = scanner.scanLocation;
    
    while (skipScanLocation < sourceString.length)
    {
      if (![nonwhitespace characterIsMember: [sourceString characterAtIndex: skipScanLocation]])
        skipScanLocation++;
      else
        break;
    }
    
    if (skipScanLocation > scanner.scanLocation)
      [scanner setScanLocation: skipScanLocation];
    
    scannedRange.location = scanner.scanLocation;
    [scanner scanUpToCharactersFromSet: whitespace intoString: &scannedString];
    scannedRange.length = scanner.scanLocation - scannedRange.location;
    
    NSUInteger characterIndex = 0;
    
    while (characterIndex < scannedString.length && [skips characterIsMember: [scannedString characterAtIndex: characterIndex]])
    {
      characterIndex++;
      scannedRange.location++;
      scannedRange.length--;
    }
    
    scannedString = [sourceString substringWithRange: scannedRange];
    characterIndex = scannedString.length;
    
    while (characterIndex > 0 && [skips characterIsMember: [scannedString characterAtIndex: characterIndex - 1]])
    {
      characterIndex--;
      scannedRange.length--;
    }
    
    scannedString = [sourceString substringWithRange: scannedRange];
    
    if ((foundURL = [self normalizedURLForString: scannedString]))
    {
      linkAttributes = @{NSLinkAttributeName: foundURL,
        NSUnderlineStyleAttributeName: @(NSSingleUnderlineStyle)};
      [editString addAttributes: linkAttributes range: scannedRange];
    }
  }
}

- (NSURL *) normalizedURLForString: (NSString *) string
{
  if ([string hasPrefix: @"http:"])
    return [NSURL URLWithString: string];
  
  if ([string hasPrefix: @"https:"])
    return [NSURL URLWithString: string];
  
  if ([string hasPrefix: @"ftp:"])
    return [NSURL URLWithString: string];
  
  if ([string hasPrefix: @"mailto:"])
    return [NSURL URLWithString: string];
  
  if ([string hasPrefix: @"www."])
    return [NSURL URLWithString: [@"http://" stringByAppendingString: string]];
  
  if ([string hasPrefix: @"ftp."])
    return [NSURL URLWithString: [@"ftp://" stringByAppendingString: string]];
  
  if ([string hasSuffix: @".com"]
      || [string hasSuffix: @".net"]
      || [string hasSuffix: @".org"]
      || [string hasSuffix: @".edu"]
      || [string hasSuffix: @".de"]
      || [string hasSuffix: @".uk"]
      || [string hasSuffix: @".cc"])
  {
    if ([string rangeOfString: @"@"].length != 0)
      return [NSURL URLWithString: [@"mailto:" stringByAppendingString: string]];
    else
      return [NSURL URLWithString: [@"http://" stringByAppendingString: string]];
  }
  
  return nil;
}

@end
