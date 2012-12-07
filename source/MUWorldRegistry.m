//
// MUWorldRegistry.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorldRegistry.h"
#import "MUProfile.h"

@interface MUWorldRegistry ()

- (void) _applicationWillTerminate: (NSNotification *) notification;
- (void) _postWorldsDidChangeNotification;
- (void) _worldsDidChange: (NSNotification *) notification;
- (void) _writeWorldsToUserDefaults;

@end

#pragma mark -

@implementation MUWorldRegistry

@synthesize worlds = _worlds;

+ (MUWorldRegistry *) defaultRegistry
{
  static MUWorldRegistry *_defaultRegistry = nil;
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
  
  if (worldsData)
    _worlds = [NSKeyedUnarchiver unarchiveObjectWithData: worldsData];
  else
    _worlds = [NSMutableArray array];
  
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
  
  _worlds = [[NSMutableArray alloc] init];
  
  return self;
}

#pragma mark - Property method implementations for worlds

- (NSMutableArray *) worlds
{
  @synchronized (self)
  {
    return _worlds;
  }
}

- (void) setWorlds: (NSArray *) newWorlds
{
  @synchronized (self)
  {
    if ([_worlds isEqualToArray: newWorlds])
      return;
    
    [self willChangeValueForKey: @"worlds"];
    
    _worlds = [newWorlds mutableCopy];
    
    [self didChangeValueForKey: @"worlds"];
    [self _postWorldsDidChangeNotification];
  }
}

- (NSUInteger) countOfWorlds
{
  @synchronized (self)
  {
    return _worlds.count;
  }
}

- (MUTreeNode *) objectInWorldsAtIndex: (NSUInteger) index
{
  @synchronized (self)
  {
    return _worlds[index];
  }
}

- (NSArray *) worldsAtIndexes: (NSIndexSet *) indexSet
{
  @synchronized (self)
  {
    return [_worlds objectsAtIndexes: indexSet];
  }
}

- (void) getWorlds: (__unsafe_unretained id *) objects range: (NSRange) range
{
  @synchronized (self)
  {
    [_worlds getObjects: objects range: range];
  }
}

- (void) insertObject: (MUTreeNode *) object inWorldsAtIndex: (NSUInteger) index
{
  object.parent = nil;
  
  @synchronized (self)
  {
    [_worlds insertObject: object atIndex: index];
  }
  
  [self _postWorldsDidChangeNotification];
}

- (void) insertWorlds: (NSArray *) objects atIndexes: (NSIndexSet *) indexes
{
  for (MUTreeNode *node in objects)
    node.parent = nil;
  
  @synchronized (self)
  {
    [_worlds insertObjects: objects atIndexes: indexes];
  }
  
  [self _postWorldsDidChangeNotification];
}

- (void) removeObjectFromWorldsAtIndex: (NSUInteger) index
{
  @synchronized (self)
  {
    [_worlds removeObjectAtIndex: index];
  }
  
  [self _postWorldsDidChangeNotification];
}

- (void) removeWorldsAtIndexes: (NSIndexSet *) indexes
{
  @synchronized (self)
  {
    [_worlds removeObjectsAtIndexes: indexes];
  }
  
  [self _postWorldsDidChangeNotification];
}

- (void) replaceObjectInWorldsAtIndex: (NSUInteger) index withObject: (MUTreeNode *) object
{
  object.parent = nil;
  
  @synchronized (self)
  {
    _worlds[index] = object;
  }
  
  [self _postWorldsDidChangeNotification];
}

- (void) replaceWorldsAtIndexes: (NSIndexSet *) indexes withWorlds: (NSArray *) objects
{
  @synchronized (self)
  {
    [_worlds replaceObjectsAtIndexes: indexes withObjects: objects];
  }
  
  [self _postWorldsDidChangeNotification];
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
