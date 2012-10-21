//
// MUFugueEditFilter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFugueEditFilter.h"

@implementation MUFugueEditFilter

+ (id) filterWithDelegate: (id) newDelegate
{
  return [[self alloc] initWithDelegate: newDelegate];
}

- (id) initWithDelegate: (id) newDelegate
{
  if (!(self = [super init]))
    return nil;
  
  _delegate = newDelegate;
  return self;
}

- (id) init
{
  return [self initWithDelegate: nil];
}

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString
{
  NSString *plainString = attributedString.string;
  NSString *fugueEditPrefix = @"FugueEdit > ";
  
  if ([plainString hasPrefix: fugueEditPrefix])
  {
    [self.delegate setInputViewString: [[plainString substringFromIndex: fugueEditPrefix.length]
                                        stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    return [NSAttributedString attributedStringWithString: @""];
  }
  else
    return attributedString;
}

- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString
{
  return attributedString;
}

@end
