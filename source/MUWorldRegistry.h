//
// MUWorldRegistry.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUWorld;
@class MUPlayer;

@interface MUWorldRegistry : NSObject
{
  NSMutableArray *worlds;
}

@property (copy,setter=setWorld:) NSMutableArray *worlds;

+ (MUWorldRegistry *) defaultRegistry;

- (void) insertObject: (MUWorld *) world inWorldsAtIndex: (unsigned) worldIndex;
- (void) removeObjectFromWorldsAtIndex: (unsigned) worldIndex;

- (unsigned) count;
- (NSUInteger) indexOfWorld: (MUWorld *) world;
- (void) removeWorld: (MUWorld *) world;
- (void) replaceWorld: (MUWorld *) oldWorld withWorld: (MUWorld *) newWorld;
- (MUWorld *) worldAtIndex: (unsigned) worldIndex;
- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
