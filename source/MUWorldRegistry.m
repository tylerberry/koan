//
// MUWorldRegistry.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorldRegistry.h"
#import "MUProfile.h"

static MUWorldRegistry *_defaultRegistry = nil;

@interface MUWorldRegistry ()

- (void) _cleanUpDefaultRegistry: (NSNotification *) notification;
- (void) _postWorldsDidChangeNotification;
- (void) _worldsDidChange: (NSNotification *) notification;
- (void) _writeWorldsToUserDefaults;

@end

#pragma mark -

@implementation MUWorldRegistry

@dynamic count, worlds;

+ (MUWorldRegistry *) defaultRegistry
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _defaultRegistry = [[MUWorldRegistry alloc] initWithWorldsFromUserDefaults]; });

  return _defaultRegistry;
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
                                           selector: @selector (_cleanUpDefaultRegistry:)
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

- (void) insertObject: (MUWorld *) world inWorldsAtIndex: (NSUInteger) worldIndex
{
  @synchronized (self)
  {
    [self willChangeValueForKey: @"worlds"];
    
    [self.mutableWorlds insertObject: world atIndex: worldIndex];
    
    [self didChangeValueForKey: @"worlds"];
    [self _postWorldsDidChangeNotification];
  }
}

- (void) removeObjectFromWorldsAtIndex: (NSUInteger) worldIndex
{
  @synchronized (self)
  {
    [self willChangeValueForKey: @"worlds"];
    
    [self.mutableWorlds removeObjectAtIndex: worldIndex];
    
    [self didChangeValueForKey: @"worlds"];
    [self _postWorldsDidChangeNotification];
  }
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

- (void) _cleanUpDefaultRegistry: (NSNotification *) notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: _defaultRegistry];
  _defaultRegistry = nil;
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
