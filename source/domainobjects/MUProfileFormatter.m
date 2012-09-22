//
// MUProfileFormatter.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfileFormatter.h"
#import "MUProfile.h"

@interface MUProfileFormatter ()

@property (unsafe_unretained, nonatomic) MUProfile *profile;

@end

#pragma mark -

@implementation MUProfileFormatter

@synthesize profile;

- (id) initWithProfile: (MUProfile *) newProfile
{
  if (!(self = [super init]))
    return nil;
  
  self.profile = newProfile;
  
  return self;
}

#pragma mark - MUFormatter protocol

- (NSFont *) font
{
  return self.profile.effectiveFont;
}

- (NSColor *) foregroundColor
{
  if (self.profile.textColor)
    return self.profile.textColor;
  else
    return [NSUnarchiver unarchiveObjectWithData: self.profile.effectiveTextColor];
}

- (NSColor *) backgroundColor
{
  if (self.profile.backgroundColor)
    return self.profile.backgroundColor;
  else
    return [NSUnarchiver unarchiveObjectWithData: self.profile.effectiveBackgroundColor];  
}

@end
