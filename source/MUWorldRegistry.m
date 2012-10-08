//
// MUWorldRegistry.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUWorldRegistry.h"
#import "MUProfile.h"

static MUWorldRegistry *defaultRegistry = nil;

@interface MUWorldRegistry ()
{
  NSMutableArray *mutableWorlds;
}

- (void) cleanUpDefaultRegistry: (NSNotification *) notification;
- (void) postWorldsDidChangeNotification;
- (void) readWorldsFromUserDefaults;
- (void) worldsDidChange: (NSNotification *) notification;
- (void) writeWorldsToUserDefaults;

@end

#pragma mark -

@implementation MUWorldRegistry

@synthesize mutableWorlds;
@dynamic count, worlds;

+ (MUWorldRegistry *) defaultRegistry
{
  if (!defaultRegistry)
  {
    defaultRegistry = [[MUWorldRegistry alloc] init];
    [defaultRegistry readWorldsFromUserDefaults];
    
    [[NSNotificationCenter defaultCenter] addObserver: defaultRegistry
                                             selector: @selector (worldsDidChange:)
                                                 name: MUWorldsDidChangeNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: defaultRegistry
                                             selector: @selector (cleanUpDefaultRegistry:)
                                                 name: NSApplicationWillTerminateNotification
                                               object: NSApp];
  }
  return defaultRegistry;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  mutableWorlds = [[NSMutableArray alloc] init];
  
  return self;
}


#pragma mark - Key-value coding accessors

- (void) insertObject: (MUWorld *) world inWorldsAtIndex: (NSUInteger) worldIndex
{
  @synchronized (self)
  {
    [self willChangeValueForKey: @"worlds"];
    [mutableWorlds insertObject: world atIndex: worldIndex];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

- (void) removeObjectFromWorldsAtIndex: (NSUInteger) worldIndex
{
  @synchronized (self)
  {
    [self willChangeValueForKey: @"worlds"];
    [mutableWorlds removeObjectAtIndex: worldIndex];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

#pragma mark - Actions

- (NSUInteger) count
{
  NSUInteger count = 0;
  
  @synchronized (self)
  {
    count = self.worlds.count;
  }
  
  return count;
}

- (NSUInteger) indexOfWorld: (MUWorld *) world
{
  NSUInteger worldIndex = NSNotFound;
  
  @synchronized (self)
  {
    worldIndex = [self.worlds indexOfObject: world];
  }
  
  return worldIndex;
}

- (void) removeWorld: (MUWorld *) world
{
  @synchronized (self)
  {
    if (![self.worlds containsObject: world])
    {
      NSLog (@"Called MUWorldRegistry-removeWorld: with argument not in worlds array.");
      return;
    }
    
    [self willChangeValueForKey: @"worlds"];
    [mutableWorlds removeObject: world];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

- (void) replaceWorld: (MUWorld *) oldWorld withWorld: (MUWorld *) newWorld
{
  @synchronized (self)
  {
    if (![self.worlds containsObject: oldWorld])
    {
      NSLog (@"Called MUWorldRegistry-replaceWorld:withWorld: with oldWorld argument not in worlds array.");
      return;
    }
    
    [self willChangeValueForKey: @"worlds"];
    mutableWorlds[[self.worlds indexOfObject: oldWorld]] = newWorld;
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

- (void) setMutableWorlds: (NSArray *) newWorlds
{
  if ([self.worlds isEqualToArray: newWorlds])
    return;
  
  [self willChangeValueForKey: @"worlds"];
  mutableWorlds = [newWorlds mutableCopy];
  [self didChangeValueForKey: @"worlds"];
  
  [self postWorldsDidChangeNotification];
}

- (MUWorld *) worldAtIndex: (NSUInteger) worldIndex
{
  MUWorld *world = nil;
  
  @synchronized (self)
  {
    world = (self.worlds)[worldIndex];
  }
  
  return world;
}

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier
{
  MUWorld *world = nil;
  
  @synchronized (self)
  {
    for (MUWorld *candidate in self.worlds)
    {
      if ([identifier isEqualToString: candidate.uniqueIdentifier])
      {
        world = candidate;
        break;
      }
    }
  }
  
  return world;
}

- (NSArray *) worlds
{
  return (NSArray *) mutableWorlds;
}

#pragma mark - Private methods

- (void) cleanUpDefaultRegistry: (NSNotification *) notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: defaultRegistry];
  defaultRegistry = nil;
}

- (void) postWorldsDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUWorldsDidChangeNotification
                                                      object: self];
}

- (void) readWorldsFromUserDefaults
{
  NSData *worldsData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPWorlds];
  
  if (!worldsData)
    return;
  
  [self setMutableWorlds: [NSKeyedUnarchiver unarchiveObjectWithData: worldsData]];
  
  for (MUTreeNode *topLevelNode in self.worlds)
    [topLevelNode recursivelyUpdateParentsWithParentNode: nil];
}

- (void) worldsDidChange: (NSNotification *) notification;
{
  [self writeWorldsToUserDefaults];
}

- (void) writeWorldsToUserDefaults
{
  [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: self.worlds]
                                            forKey: MUPWorlds];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
