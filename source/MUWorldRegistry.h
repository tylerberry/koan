//
// MUWorldRegistry.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUWorld;
@class MUPlayer;

@interface MUWorldRegistry : NSObject

@property (unsafe_unretained, readonly) NSUInteger count;
@property (unsafe_unretained, readonly) NSArray *worlds;
@property (strong, nonatomic) NSMutableArray *mutableWorlds;

+ (MUWorldRegistry *) defaultRegistry;

- (void) insertObject: (MUWorld *) world inWorldsAtIndex: (NSUInteger) worldIndex;
- (void) removeObjectFromWorldsAtIndex: (NSUInteger) worldIndex;

- (NSUInteger) indexOfWorld: (MUWorld *) world;
- (void) removeWorld: (MUWorld *) world;
- (void) replaceWorld: (MUWorld *) oldWorld withWorld: (MUWorld *) newWorld;
- (MUWorld *) worldAtIndex: (NSUInteger) worldIndex;
- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier;

@end
