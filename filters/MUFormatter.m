//
// MUFormatter.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUFormatter.h"

@implementation MUFormatter

+ (id) formatterForTesting
{
  return [self formatterWithForegroundColor: [MUFormatter testingForeground] backgroundColor: [MUFormatter testingBackground] font: [MUFormatter testingFont]];
}

+ (id) formatterWithForegroundColor: (NSColor *) fore backgroundColor: (NSColor *) back font: (NSFont *) font
{
  return [[[self alloc] initWithForegroundColor: fore backgroundColor: back font: font] autorelease];
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

- (id) initWithForegroundColor: (NSColor *) fore backgroundColor: (NSColor *) back font: (NSFont *) aFont
{
  if (!(self = [super init]))
    return nil;
  foreground = [fore retain];
  background = [back retain];
  font = [aFont retain];
  return self;
}

- (void) dealloc
{
  [foreground release];
  [background release];
  [font release];
  [super dealloc];
}

- (NSColor *) background
{
  return background;
}

- (NSFont *) font
{
  return font;
}

- (NSColor *) foreground
{
  return foreground;
}

@end
