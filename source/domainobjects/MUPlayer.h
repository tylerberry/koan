//
// MUPlayer.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUWorld.h"

@interface MUPlayer : MUTreeNode <NSCoding, NSCopying>
{
  NSString *password;
}

@property (copy) NSString *password;
@property (readonly) NSString *loginString;
@property (readonly) NSString *uniqueIdentifier;
@property (readonly) NSString *windowTitle;

+ (MUPlayer *) playerWithName: (NSString *) newName
  									 password: (NSString *) newPassword;

// Designated initializer.
- (id) initWithName: (NSString *) newName
           password: (NSString *) newPassword;

@end
