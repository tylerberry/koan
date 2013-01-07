//
// MUPlayer.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"

@interface MUPlayer : MUTreeNode

@property (copy) NSString *fugueEditPrefix;
@property (copy) NSString *password;

@property (readonly) NSString *loginString;
@property (readonly) NSString *windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName
  									 password: (NSString *) newPassword;

// Designated initializer.
- (id) initWithName: (NSString *) newName
           password: (NSString *) newPassword;

@end
