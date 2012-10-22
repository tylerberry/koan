//
// MUFolder.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFolder.h"

@implementation MUFolder

- (NSImage *) icon
{
  return [NSImage imageNamed: @"NSFolder"];
}

- (NSString *) uniqueIdentifier
{
  NSMutableString *result = [NSMutableString stringWithString: @"folder:"];
  NSArray *tokens = [self.name componentsSeparatedByString: @" "];
  
  if (tokens.count > 0)
  {
    [result appendFormat: @"%@", [tokens[0] lowercaseString]];
    
    for (NSUInteger i = 1; i < tokens.count; i++)
      [result appendFormat: @".%@", [tokens[i] lowercaseString]];
  }
  return result;
}

@end
