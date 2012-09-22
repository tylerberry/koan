//
// MUFugueEditFilter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFugueEditFilter.h"

@implementation MUFugueEditFilter

@synthesize delegate;

+ (id) filterWithDelegate: (id) newDelegate
{
  return [[self alloc] initWithDelegate: newDelegate];
}

- (id) initWithDelegate: (id) newDelegate
{
  if (!(self = [super init]))
    return nil;
  
  delegate = newDelegate;
  return self;
}

- (id) init
{
  return [self initWithDelegate: nil];
}

- (NSAttributedString *) filter: (NSAttributedString *) string
{
  NSString *plainString = [string string];
  NSString *fugueEditPrefix = @"FugueEdit > ";
  
  if ([plainString hasPrefix: fugueEditPrefix])
  {
    [self.delegate setInputViewString: [[plainString substringFromIndex: fugueEditPrefix.length]
                                        stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    return [NSAttributedString attributedStringWithString: @""];
  }
  else
    return string;
}

@end
