//
// MUProfileRegistry.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfileRegistry.h"
#import "MUProfile.h"

@interface MUProfileRegistry ()

- (void) _cleanUpDefaultRegistry: (NSNotification *) notification;
- (void) _startObservingWritableValuesForProfile: (MUProfile *) profile;
- (void) _stopObservingWritableValuesForProfile: (MUProfile *) profile;
- (void) _writeProfilesToUserDefaults;

@end

#pragma mark -

@implementation MUProfileRegistry
{
  NSMutableDictionary *_mutableProfiles;
}

@dynamic profiles;

+ (instancetype) defaultRegistry
{
  static MUProfileRegistry *_defaultRegistry = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _defaultRegistry = [[MUProfileRegistry alloc] initWithProfilesFromUserDefaults]; });
  
  return _defaultRegistry;
}

- (instancetype) init
{
  return [self initWithProfiles: @{}];
}

- (instancetype) initWithProfiles: (NSDictionary *) profiles
{
  if (!(self = [super init]))
    return nil;
  
  _mutableProfiles = [profiles mutableCopy];
  
  for (NSString *key in _mutableProfiles.allKeys)
  {
    MUProfile *profile = _mutableProfiles[key];
    
    [self _startObservingWritableValuesForProfile: profile];
  }
  
  return self;
}

- (instancetype) initWithProfilesFromUserDefaults
{
  NSData *profilesDataFromUserDefaults = [[NSUserDefaults standardUserDefaults] dataForKey: MUPProfiles];
  NSDictionary *profilesFromUserDefaults;
  
  if (profilesDataFromUserDefaults)
    profilesFromUserDefaults = [NSKeyedUnarchiver unarchiveObjectWithData: profilesDataFromUserDefaults];
  else
    profilesFromUserDefaults = @{};
  
  return [self initWithProfiles: profilesFromUserDefaults];
}
- (void) dealloc
{
  for (MUProfile *profile in _mutableProfiles)
  {
    [self _stopObservingWritableValuesForProfile: profile];
  }
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if ([object isKindOfClass: [MUProfile class]])
  {
    if ([[MUProfile writableProperties] containsObject: keyPath])
    {
      [self _writeProfilesToUserDefaults];
      return;
    }
  }
  
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

#pragma mark - Properties

- (NSDictionary *) profiles
{
  @synchronized (self)
  {
    return _mutableProfiles;
  }
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
  @synchronized (self)
  {
    MUProfile *rval = _mutableProfiles[profile.uniqueIdentifier];
    if (!rval)
    {
      rval = profile;
      _mutableProfiles[rval.uniqueIdentifier] = rval;
      [self _startObservingWritableValuesForProfile: rval];
      [self _writeProfilesToUserDefaults];
    }
    return rval;
  }
}

- (MUProfile *) profileForUniqueIdentifier: (NSString *) identifier
{
  @synchronized (self)
  {
    return _mutableProfiles[identifier];
  }
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
  @synchronized (self)
  {
    [self _stopObservingWritableValuesForProfile: _mutableProfiles[identifier]];
    [_mutableProfiles removeObjectForKey: identifier];
    [self _writeProfilesToUserDefaults];
  }
}

- (void) removeAllProfilesForWorld: (MUWorld *) world
{
  for (NSUInteger i = 0; i < world.children.count; i++)
  {
    [self removeProfileForWorld: world player: world.children[i]];
  }
  
  [self removeProfileForWorld: world];
}

#pragma mark - Private methods

- (void) _cleanUpDefaultRegistry: (NSNotification *) notification
{
  [self _writeProfilesToUserDefaults];
}

- (void) _startObservingWritableValuesForProfile: (MUProfile *) profile
{
  for (NSString *keyPath in [MUProfile writableProperties])
  {
    [profile addObserver: self forKeyPath: keyPath options: 0 context: nil];
  }
}

- (void) _stopObservingWritableValuesForProfile: (MUProfile *) profile
{
  for (NSString *keyPath in [MUProfile writableProperties])
  {
    [profile removeObserver: self forKeyPath: keyPath];
  }
}

- (void) _writeProfilesToUserDefaults
{
  [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: self.profiles]
                                            forKey: MUPProfiles];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
