//
// MUPlayer.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUWorld.h"

@interface MUPlayer : MUTreeNode <NSCoding, NSCopying>

@property (copy) NSString *password;
@property (unsafe_unretained, readonly) NSString *loginString;
@property (unsafe_unretained, readonly) NSString *uniqueIdentifier;
@property (unsafe_unretained, readonly) NSString *windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName
  									 password: (NSString *) newPassword;

// Designated initializer.
- (id) initWithName: (NSString *) newName
           password: (NSString *) newPassword;

@end
