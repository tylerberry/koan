//
// MUProfileFormatter.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUFormatter.h"

@class MUProfile;

@interface MUProfileFormatter : NSObject <MUFormatter>
{
  MUProfile *profile;
}

- (id) initWithProfile: (MUProfile *) newProfile;

@end
