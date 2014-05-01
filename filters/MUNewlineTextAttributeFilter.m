//
// MUNewlineTextAttributeFilter.m
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUNewlineTextAttributeFilter.h"

@implementation MUNewlineTextAttributeFilter

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  // Trim background color attributes from newlines. Some lazy ANSI art doesn't reset this.

  NSMutableAttributedString *normalizedString = [attributedString mutableCopy];

  NSRange newlineFoundRange;
  NSRange searchRange = NSMakeRange (0, attributedString.length);

  newlineFoundRange = [attributedString.string rangeOfString: @"\n" options: 0 range: searchRange];

  while (newlineFoundRange.location != NSNotFound)
  {
    NSMutableDictionary *attributes = [[attributedString attributesAtIndex: newlineFoundRange.location
                                                               effectiveRange: NULL] mutableCopy];
    [attributes removeObjectForKey: MUInverseColorsAttributeName];
    [attributes removeObjectForKey: NSBackgroundColorAttributeName];
    attributes[MUCustomBackgroundColorAttributeName] = @(MUDefaultBackgroundColorTag);

    [normalizedString setAttributes: attributes range: newlineFoundRange];

    searchRange = NSMakeRange (newlineFoundRange.location + newlineFoundRange.length,
                               attributedString.length - newlineFoundRange.location - newlineFoundRange.length);

    newlineFoundRange = [attributedString.string rangeOfString: @"\n" options: 0 range: searchRange];
  }

  return normalizedString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return [self filterCompleteLine: attributedString];
}

@end
