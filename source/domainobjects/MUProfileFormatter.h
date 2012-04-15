//
// MUProfileFormatter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUFormatter.h"

@class MUProfile;

@interface MUProfileFormatter : NSObject <MUFormatter>

- (id) initWithProfile: (MUProfile *) newProfile;

@end
