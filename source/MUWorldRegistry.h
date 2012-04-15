//
// MUWorldRegistry.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUWorld;
@class MUPlayer;

@interface MUWorldRegistry : NSObject
{
  NSMutableArray *worlds;
}

@property (copy, setter=setMutableWorlds:) NSMutableArray *worlds;

+ (MUWorldRegistry *) defaultRegistry;

- (void) insertObject: (MUWorld *) world inWorldsAtIndex: (NSUInteger) worldIndex;
- (void) removeObjectFromWorldsAtIndex: (NSUInteger) worldIndex;

- (NSUInteger) count;
- (NSUInteger) indexOfWorld: (MUWorld *) world;
- (void) removeWorld: (MUWorld *) world;
- (void) replaceWorld: (MUWorld *) oldWorld withWorld: (MUWorld *) newWorld;
- (MUWorld *) worldAtIndex: (NSUInteger) worldIndex;
- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
