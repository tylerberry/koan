//
// MUProfileFormatter.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUProfileFormatter.h"
#import "MUProfile.h"

@implementation MUProfileFormatter

- (id) initWithProfile: (MUProfile *) newProfile
{
  if (!(self = [super init]))
    return nil;
  
  profile = [newProfile retain];
  
  return self;
}

- (void) dealloc
{
  [profile release];
  [super dealloc];
}

#pragma mark -
#pragma mark MUFormatter protocol

- (NSFont *) font
{
  return [profile effectiveFont];
}

- (NSColor *) foreground
{
  if ([profile textColor])
    return [profile textColor];
  else
    return [NSUnarchiver unarchiveObjectWithData: [profile effectiveTextColor]];  
}

- (NSColor *) background
{
  if ([profile backgroundColor])
    return [profile backgroundColor];
  else
    return [NSUnarchiver unarchiveObjectWithData: [profile effectiveBackgroundColor]];  
}

@end
