//
// MUPlayer.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUWorld.h"

@interface MUPlayer : MUTreeNode <NSCoding, NSCopying>

@property (copy) NSString *password;
@property (readonly) NSString *loginString;
@property (readonly) NSString *windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName
  									 password: (NSString *) newPassword;

// Designated initializer.
- (id) initWithName: (NSString *) newName
           password: (NSString *) newPassword;

@end
