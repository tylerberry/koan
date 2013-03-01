//
// MURegexTestFilter.m
//
// Copyright (c) 2013 3James Software.
//

#import "MURegexTestFilter.h"

#import "AGRegex.h"

@implementation MURegexTestFilter

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  AGRegex *regex = [AGRegex regexWithPattern: @"^MOTD:"];
  NSString *plainString = attributedString.string;
  
  if ([regex findInString: plainString])
    return [NSAttributedString attributedStringWithString: @""];
  
  return attributedString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return [self filterCompleteLine: attributedString];
}

@end
