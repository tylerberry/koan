//
// MUPlayer.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"

@interface MUPlayer : MUTreeNode

@property (copy) NSString *fugueEditPrefix;
@property (copy) NSString *password;
@property (readonly) MUWorld *world;

@property (readonly) NSString *loginString;
@property (readonly) NSString *windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName;

// Designated initializer.
- (id) initWithName: (NSString *) newName;

@end
