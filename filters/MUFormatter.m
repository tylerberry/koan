//
// MUFormatter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFormatter.h"

@implementation MUFormatter

@synthesize backgroundColor, font, foregroundColor;

+ (id) formatterForTesting
{
  return [self formatterWithForegroundColor: [MUFormatter testingForeground]
                            backgroundColor: [MUFormatter testingBackground]
                                       font: [MUFormatter testingFont]];
}

+ (id) formatterWithForegroundColor: (NSColor *) foregroundColor
                    backgroundColor: (NSColor *) backgroundColor
                               font: (NSFont *) font
{
  return [[self alloc] initWithForegroundColor: foregroundColor
                               backgroundColor: backgroundColor
                                          font: font];
}

+ (NSColor *) testingBackground
{
  return [NSColor blackColor];
}

+ (NSFont *) testingFont
{
  return [NSFont systemFontOfSize: [NSFont systemFontSize]];
}

+ (NSColor *) testingForeground
{
  return [NSColor lightGrayColor];
}

- (id) initWithForegroundColor: (NSColor *) newForegroundColor
               backgroundColor: (NSColor *) newBackgroundColor
                          font: (NSFont *) newFont
{
  if (!(self = [super init]))
    return nil;
  
  foregroundColor = newForegroundColor;
  backgroundColor = newBackgroundColor;
  font = newFont;
  
  return self;
}

@end
