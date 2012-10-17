//
// MUProfileRegistry.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfileRegistry.h"
#import "MUProfile.h"

static MUProfileRegistry *defaultRegistry = nil;

@interface MUProfileRegistry ()

@property (strong) NSMutableDictionary *mutableProfiles;

- (void) cleanUpDefaultRegistry: (NSNotification *) notification;
- (void) readProfilesFromUserDefaults;
- (void) writeProfilesToUserDefaults;

@end

#pragma mark -

@implementation MUProfileRegistry

@dynamic profiles;

+ (MUProfileRegistry *) defaultRegistry
{
  if (!defaultRegistry)
  {
    defaultRegistry = [[MUProfileRegistry alloc] init];
    [defaultRegistry readProfilesFromUserDefaults];
    
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
  
  _mutableProfiles = [[NSMutableDictionary alloc] init];
  
  return self;
}

#pragma mark - Properties

- (NSDictionary *) profiles
{
  return self.mutableProfiles;
}

#pragma mark - Accessor methods

- (MUProfile *) profileForWorld: (MUWorld *) world
{
  return [self profileForWorld: world player: nil];
}

- (MUProfile *) profileForWorld: (MUWorld *) world player: (MUPlayer *) player
{
  return [self profileForProfile: [MUProfile profileWithWorld: world player: player]];
}

- (MUProfile *) profileForProfile: (MUProfile *) profile
{
  MUProfile *rval = [self profileForUniqueIdentifier: profile.uniqueIdentifier];
  if (!rval)
  {
    rval = profile;
    self.mutableProfiles[rval.uniqueIdentifier] = rval;
    [self writeProfilesToUserDefaults];
  }
  return rval;
}

- (MUProfile *) profileForUniqueIdentifier: (NSString *) identifier
{
  return self.profiles[identifier];
}

- (BOOL) containsProfileForWorld: (MUWorld *) world
{
  return [self containsProfileForWorld: world player: nil];
}

- (BOOL) containsProfileForWorld: (MUWorld *) world player: (MUPlayer *) player
{
  MUProfile *profile = [MUProfile profileWithWorld: world player: player];
  return [self containsProfile: profile];
}

- (BOOL) containsProfile: (MUProfile *) profile
{
  return [self containsProfileForUniqueIdentifier: profile.uniqueIdentifier];
}

- (BOOL) containsProfileForUniqueIdentifier: (NSString *) identifier
{
  return [self profileForUniqueIdentifier: identifier] != nil;  
}

- (void) removeProfile: (MUProfile *) profile
{
  [self removeProfileForUniqueIdentifier: profile.uniqueIdentifier];
}

- (void) removeProfileForWorld: (MUWorld *) world
{
  [self removeProfileForWorld: world player: nil];
}

- (void) removeProfileForWorld: (MUWorld *) world player: (MUPlayer *) player
{
  MUProfile *profile = [self profileForWorld: world player: player];
  
  [self removeProfile: profile];
}

- (void) removeProfileForUniqueIdentifier: (NSString *) identifier
{
  [self.mutableProfiles removeObjectForKey: identifier];
  [self writeProfilesToUserDefaults];
}

- (void) removeAllProfilesForWorld: (MUWorld *) world
{
  for (NSUInteger i = 0; i < world.children.count; i++)
  {
    [self removeProfileForWorld: world
                         player: world.children[i]];
  }
  
  [self removeProfileForWorld: world];
}

#pragma mark - Private methods

- (void) cleanUpDefaultRegistry: (NSNotification *) notification
{
  [[NSNotificationCenter defaultCenter] removeObserver: defaultRegistry];
  defaultRegistry = nil;
}

- (void) readProfilesFromUserDefaults
{
  NSData *profilesData = [[NSUserDefaults standardUserDefaults] dataForKey: MUPProfiles];
  
  if (profilesData)
    self.mutableProfiles = [NSKeyedUnarchiver unarchiveObjectWithData: profilesData];
}

#if 0
- (void) setMutableProfiles: (NSDictionary *) newProfiles
{
  if ([self.mutableProfiles isEqual: newProfiles])
    return;
  
  _mutableProfiles = [newProfiles mutableCopy];
  
  [self writeProfilesToUserDefaults];
}
#endif

- (void) writeProfilesToUserDefaults
{
  [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: self.mutableProfiles]
                                            forKey: MUPProfiles];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
