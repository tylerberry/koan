//
// MUWorldRegistry.m
//
// Copyright (c) 2010 3James Software.
//

#import "MUServices.h"
#import "MUProfile.h"

static MUWorldRegistry *defaultRegistry = nil;

@interface MUWorldRegistry (Private)

- (void) cleanUpDefaultRegistry: (NSNotification *) notification;
- (void) postWorldsDidChangeNotification;
- (void) readWorldsFromUserDefaults;
- (void) setWorlds: (NSArray *) newWorlds;
- (void) worldsDidChange: (NSNotification *) notification;
- (void) writeWorldsToUserDefaults;

@end

#pragma mark -

@implementation MUWorldRegistry

@synthesize worlds;

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
  
  worlds = [[NSMutableArray alloc] init];
  
  return self;
}

- (void) dealloc
{
  [worlds release];
  [super dealloc];
}

#pragma mark -
#pragma mark Key-value coding accessors

- (void) insertObject: (MUWorld *) world inWorldsAtIndex: (unsigned) worldIndex
{
  @synchronized (self)
  {
    [self willChangeValueForKey: @"worlds"];
    [worlds insertObject: world atIndex: worldIndex];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

- (void) removeObjectFromWorldsAtIndex: (unsigned) worldIndex
{
  @synchronized (self)
  {
    [self willChangeValueForKey: @"worlds"];
    [worlds removeObjectAtIndex: worldIndex];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

#pragma mark -
#pragma mark Actions

- (unsigned) count
{
  unsigned count = 0;
  
  @synchronized (self)
  {
    count = [worlds count];
  }
  
  return count;
}

- (int) indexOfWorld: (MUWorld *) world
{
  int index = NSNotFound;
  
  @synchronized (self)
  {
    index = [worlds indexOfObject: world];
  }
  
  return index;
}

- (void) removeWorld: (MUWorld *) world
{
  @synchronized (self)
  {
    if (![worlds containsObject: world])
      return;
    
    [self willChangeValueForKey: @"worlds"];
    [worlds removeObject: world];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

- (void) replaceWorld: (MUWorld *) oldWorld withWorld: (MUWorld *) newWorld
{
  @synchronized (self)
  {
    if (![worlds containsObject: oldWorld])
      return;
    
    [self willChangeValueForKey: @"worlds"];
    [worlds replaceObjectAtIndex: [worlds indexOfObject: oldWorld] withObject: newWorld];
    [self didChangeValueForKey: @"worlds"];
    [self postWorldsDidChangeNotification];
  }
}

- (MUWorld *) worldAtIndex: (unsigned) worldIndex
{
  MUWorld *world = nil;
  
  @synchronized (self)
  {
    world = [worlds objectAtIndex: worldIndex];
  }
  
  return world;
}

- (MUWorld *) worldForUniqueIdentifier: (NSString *) identifier
{
  MUWorld *world = nil;
  
  @synchronized (self)
  {
    for (MUWorld *candidate in worlds)
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

@end

#pragma mark -

@implementation MUWorldRegistry (Private)

- (void) cleanUpDefaultRegistry: (NSNotification *) notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: defaultRegistry];
  [defaultRegistry release];
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
  
  [self setWorlds: [NSKeyedUnarchiver unarchiveObjectWithData: worldsData]];
  
  for (unsigned i = 0; i < [worlds count]; i++)
  {
    MUWorld *world = [worlds objectAtIndex: i];
    
    for (unsigned j = 0; j < [[world players] count]; j++)
    {
      MUPlayer *player = [[world players] objectAtIndex: j];
      player.world = world;
      
      MUProfile *profile = [[MUServices profileRegistry] profileForWorld: world player: player];
      profile.world = world;
      profile.player = player;
    }
  }
}

- (void) setWorlds: (NSArray *) newWorlds
{
  if (worlds == newWorlds)
    return;
  
  [self willChangeValueForKey: @"worlds"];
  [worlds release];
  worlds = [newWorlds mutableCopy];
  [self didChangeValueForKey: @"worlds"];
  
  [self postWorldsDidChangeNotification];
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
