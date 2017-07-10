//
// MUProfilesSection.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUSection.h"

@interface MUProfilesSection : MUSection

- (instancetype) initWithCoder: (NSCoder *) decoder NS_UNAVAILABLE;
- (instancetype) initWithName: (NSString *) name NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithName: (NSString *) name children: (NSArray *) children NS_UNAVAILABLE;

@end
