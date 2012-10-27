//
// MUWorldRegistry.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorldRegistry.h"
#import "MUProfile.h"

static MUWorldRegistry *_defaultRegistry = nil;

@interface MUWorldRegistry ()

- (void) _applicationWillTerminate: (NSNotification *) notification;
- (void) _postWorldsDidChangeNotification;
- (void) _worldsDidChange: (NSNotification *) notification;
- (void) _writeWorldsToUserDefaults;

@end

#pragma mark -

@implementation MUWorldRegistry

@dynamic worlds;

+ (MUWorldRegistry *) defaultRegistry
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _defaultRegistry = [[MUWorldRegistry alloc] initWithWorldsFromUserDefaults]; });

  return _defaultRegistry;
}

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
  NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey: key];
  
  if ([key isEqualToString: @"worlds"])
  {
    keyPaths = [keyPaths setByAddingObject: @"mutableWorlds"];
  }
  
  return keyPaths;
}

- (id) initWithWorldsFromUserDefaults
{
  if (!(self = [super init]))
    return nil;
  
  NSData *worldsData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPWorlds];
  
  if (!worldsData)
    return nil;
  
  _mutableWorlds = [NSKeyedUnarchiver unarchiveObjectWithData: worldsData];
  
  for (MUTreeNode *topLevelNode in self.worlds)
    [topLevelNode recursivelyUpdateParentsWithParentNode: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_worldsDidChange:)
                                               name: MUWorldsDidChangeNotification
                                             object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_applicationWillTerminate:)
                                               name: NSApplicationWillTerminateNotification
                                             object: NSApp];
  
  return self;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _mutableWorlds = [[NSMutableArray alloc] init];
  
  return self;
}

#pragma mark - Key-value coding accessors

- (NSUInteger) countOfWorlds
{
  return _mutableWorlds.count;
}

- (MUTreeNode *) objectInWorldsAtIndex: (NSUInteger) index
{
  return _mutableWorlds[index];
}

- (NSArray *) worldsAtIndexes: (NSIndexSet *) indexSet
{
  return [_mutableWorlds objectsAtIndexes: indexSet];
}

- (void) getWorlds: (__unsafe_unretained id *) objects range: (NSRange) range
{
  [_mutableWorlds getObjects: objects range: range];
}

- (void) insertObject: (MUTreeNode *) object inWorldsAtIndex: (NSUInteger) index
{
  object.parent = nil;
  [_mutableWorlds insertObject: object atIndex: index];
}

- (void) insertWorlds: (NSArray *) objects atIndexes: (NSIndexSet *) indexes
{
  for (MUTreeNode *node in objects)
    node.parent = nil;
  
  [_mutableWorlds insertObjects: objects atIndexes: indexes];
}

- (void) removeObjectFromWorldsAtIndex: (NSUInteger) index
{
  [_mutableWorlds removeObjectAtIndex: index];
}

- (void) removeWorldsAtIndexes: (NSIndexSet *) indexes
{
  [_mutableWorlds removeObjectsAtIndexes: indexes];
}

- (void) replaceObjectInWorldsAtIndex: (NSUInteger) index withObject: (MUTreeNode *) object
{
  object.parent = nil;
  _mutableWorlds[index] = object;
}

- (void) replaceWorldsAtIndexes: (NSIndexSet *) indexes withWorlds: (NSArray *) objects
{
  [_mutableWorlds replaceObjectsAtIndexes: indexes withObjects: objects];
}

#pragma mark - Actions

- (NSUInteger) count
{
  @synchronized (self)
  {
    return _mutableWorlds.count;
  }
}

- (NSUInteger) indexOfWorld: (MUWorld *) world
{
  @synchronized (self)
  {
    return [_mutableWorlds indexOfObject: world];
  }
}

- (void) removeWorld: (MUWorld *) world
{
  @synchronized (self)
  {
    if (![_mutableWorlds containsObject: world])
    {
      NSLog (@"Called MUWorldRegistry-removeWorld: with argument not in worlds array.");
      return;
    }
    
    [self willChangeValueForKey: @"worlds"];
    
    [self.mutableWorlds removeObject: world];
    
    [self didChangeValueForKey: @"worlds"];
    [self _postWorldsDidChangeNotification];
  }
}

- (void) replaceWorld: (MUWorld *) oldWorld withWorld: (MUWorld *) newWorld
{
  @synchronized (self)
  {
    if (![_mutableWorlds containsObject: oldWorld])
    {
      NSLog (@"Called MUWorldRegistry-replaceWorld:withWorld: with oldWorld argument not in worlds array.");
      return;
    }
    
    [self willChangeValueForKey: @"worlds"];
    
    [_mutableWorlds replaceObjectAtIndex: [_mutableWorlds indexOfObject: oldWorld] withObject: newWorld];
    
    [self didChangeValueForKey: @"worlds"];
    [self _postWorldsDidChangeNotification];
  }
}

- (void) setMutableWorlds: (NSArray *) newWorlds
{
  @synchronized (self)
  {
    if ([_mutableWorlds isEqualToArray: newWorlds])
      return;
    
    [self willChangeValueForKey: @"worlds"];
    
    _mutableWorlds = [newWorlds mutableCopy];
    
    [self didChangeValueForKey: @"worlds"];
    [self _postWorldsDidChangeNotification];
  }
}

- (MUWorld *) worldAtIndex: (NSUInteger) worldIndex
{
  @synchronized (self)
  {
    return _mutableWorlds[worldIndex];
  }
}

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier
{
  @synchronized (self)
  {
    for (MUWorld *candidate in self.worlds)
    {
      if ([identifier isEqualToString: candidate.uniqueIdentifier])
        return candidate;
    }
  }
  
  return nil;
}

- (NSArray *) worlds
{
  @synchronized (self)
  {
    return (NSArray *) self.mutableWorlds;
  }
}

#pragma mark - Private methods

- (void) _applicationWillTerminate: (NSNotification *) notification
{
  [self _writeWorldsToUserDefaults];
}

- (void) _postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

- (void) _worldsDidChange: (NSNotification *) notification;
{
  [self _writeWorldsToUserDefaults];
}

- (void) _writeWorldsToUserDefaults
{
  [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: self.worlds]
                                            forKey: MUPWorlds];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
