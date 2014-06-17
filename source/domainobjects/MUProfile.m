//
// MUProfile.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfile.h"

#import "MUApplicationController.h"
#import "MUMUDConnection.h"
#import "MUTextLogger.h"
#import "MUWorldRegistry.h"

static const int32_t currentProfileVersion = 4;

@interface MUProfile ()

- (void) _startObservingUserDefaultsController;
- (void) _stopObservingUserDefaultsController;

@end

#pragma mark -

@implementation MUProfile

@dynamic effectiveBackgroundColor, effectiveFont, effectiveLinkColor, effectiveSystemTextColor, effectiveTextColor;
@dynamic hasLoginInformation, hostname, loginString, uniqueIdentifier, windowTitle;

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
  NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey: key];
  
  if ([key isEqualToString: @"effectiveFont"])
  {
    keyPaths = [keyPaths setByAddingObject: @"font"];
  }
  else if ([key isEqualToString: @"effectiveBackgroundColor"])
  {
    keyPaths = [keyPaths setByAddingObject: @"backgroundColor"];
  }
  else if ([key isEqualToString: @"effectiveLinkColor"])
  {
    keyPaths = [keyPaths setByAddingObject: @"linkColor"];
  }
  else if ([key isEqualToString: @"effectiveSystemTextColor"])
  {
    keyPaths = [keyPaths setByAddingObject: @"systemTextColor"];
  }
  else if ([key isEqualToString: @"effectiveTextColor"])
  {
    keyPaths = [keyPaths setByAddingObject: @"textColor"];
  }
  
  return keyPaths;
}\

+ (instancetype) profileWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
{
  return [[self alloc] initWithWorld: newWorld
                              player: newPlayer];
}

+ (instancetype) profileWithWorld: (MUWorld *) newWorld
{
  return [[self alloc] initWithWorld: newWorld];
}

- (instancetype) initWithWorld: (MUWorld *) newWorld
              player: (MUPlayer *) newPlayer
         autoconnect: (BOOL) newAutoconnect
                font: (NSFont *) newFont
     backgroundColor: (NSColor *) newBackgroundColor
           linkColor: (NSColor *) newLinkColor
     systemTextColor: (NSColor *) newSystemTextColor
           textColor: (NSColor *) newTextColor
{
  if (!(self = [super init]))
    return nil;
  
  _world = newWorld;
  _player = newPlayer;
  _autoconnect = newAutoconnect;
  _font = [newFont copy];
  _backgroundColor = [newBackgroundColor copy];
  _linkColor = [newLinkColor copy];
  _systemTextColor = [newSystemTextColor copy];
  _textColor = [newTextColor copy];
  
  [self _startObservingUserDefaultsController];
  
  return self;
}

- (instancetype) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
{
  return [self initWithWorld: newWorld
                      player: newPlayer
                 autoconnect: NO
                        font: nil
             backgroundColor: nil
                   linkColor: nil
             systemTextColor: nil
                   textColor: nil];
}

- (instancetype) initWithWorld: (MUWorld *) newWorld
{
  return [self initWithWorld: newWorld player: nil];
}

- (void) dealloc
{
  [self _stopObservingUserDefaultsController];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == [NSUserDefaultsController sharedUserDefaultsController])
  {
    if ([keyPath isEqualToString: [MUApplicationController keyPathForBackgroundColor]])
    {
      if (!self.backgroundColor)
      {
        [self willChangeValueForKey: @"effectiveBackgroundColor"];
        [self didChangeValueForKey: @"effectiveBackgroundColor"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForFont]])
    {
      if (!self.font)
      {
        [self willChangeValueForKey: @"effectiveFont"];
        [self didChangeValueForKey: @"effectiveFont"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForLinkColor]])
    {
      if (!self.linkColor)
      {
        [self willChangeValueForKey: @"effectiveLinkColor"];
        [self didChangeValueForKey: @"effectiveLinkColor"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForSystemTextColor]])
    {
      if (!self.systemTextColor)
      {
        [self willChangeValueForKey: @"effectiveSystemTextColor"];
        [self didChangeValueForKey: @"effectiveSystemTextColor"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForTextColor]])
    {
      if (!self.textColor)
      {
        [self willChangeValueForKey: @"effectiveTextColor"];
        [self didChangeValueForKey: @"effectiveTextColor"];
      }
      return;
    }
  }
  
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

#pragma mark - Actions

- (MUMUDConnection *) createNewMUDConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate, MUFugueEditFilterDelegate> *) delegate
{
  return [MUMUDConnection connectionWithProfile: self delegate: delegate];
}

- (MUFilter *) createLogger
{
  if (self.player)
    return [MUTextLogger filterWithWorld: self.world player: self.player];
  else
    return [MUTextLogger filterWithWorld: self.world];
}

#pragma mark - Derived property method implementations

- (NSColor *) effectiveBackgroundColor
{
  if (self.backgroundColor)
    return self.backgroundColor;
  else
  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPBackgroundColor]];
  }
}

- (NSFont *) effectiveFont
{
  if (self.font)
    return self.font;
  else
  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPFont]];
  }
}

- (NSColor *) effectiveLinkColor
{
  if (self.linkColor)
    return self.linkColor;
  else
  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPLinkColor]];
  }
}

- (NSColor *) effectiveSystemTextColor
{
  if (self.systemTextColor)
    return self.systemTextColor;
  else
  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPSystemTextColor]];
  }
}

- (NSColor *) effectiveTextColor
{
  if (self.textColor)
    return self.textColor;
  else
  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPTextColor]];
  }
}

#pragma mark - Property method implementations

- (BOOL) hasLoginInformation
{
  return self.loginString != nil;
}

- (NSString *) hostname
{
  return self.world.hostname;
}

- (NSString *) loginString
{
  if (self.player)
    return self.player.loginString;
  else
    return nil;
}

- (NSString *) uniqueIdentifier
{
  if (self.player)
    return self.player.uniqueIdentifier;
  else
    return self.world.uniqueIdentifier;
}

- (NSString *) windowTitle
{
  return (self.player ? self.player.windowTitle : self.world.windowTitle);
}

- (NSArray *) writableProperties
{
  return @[@"autoconnect", @"font", @"backgroundColor", @"linkColor", @"textColor"];
}

#pragma mark - NSSecureCoding protocol

+ (BOOL) supportsSecureCoding
{
  return YES;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentProfileVersion forKey: @"version"];
  [encoder encodeObject: self.world.uniqueIdentifier forKey: @"worldIdentifier"];
  [encoder encodeObject: self.player.uniqueIdentifier forKey: @"playerIdentifier"];
  [encoder encodeBool: self.autoconnect forKey: @"autoconnect"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.font] forKey: @"font"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.backgroundColor] forKey: @"backgroundColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.linkColor] forKey: @"linkColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.systemTextColor] forKey: @"systemTextColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.textColor] forKey: @"textColor"];
}

- (instancetype) initWithCoder: (NSCoder *) decoder
{
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  if (version < 3) // Versions prior to 3 did not track world or player identifiers and are useless.
    return nil;
  
  NSString *worldIdentifier = [decoder decodeObjectOfClass: [NSString class] forKey: @"worldIdentifier"];
  MUWorld *world = [[MUWorldRegistry defaultRegistry] worldForUniqueIdentifier: worldIdentifier];
  
  NSString *playerIdentifier = [decoder decodeObjectOfClass: [NSString class] forKey: @"playerIdentifier"];
  MUPlayer *player = nil;
  
  if (playerIdentifier)
  {
    for (MUPlayer *candidatePlayer in world.children)
    {
      if ([candidatePlayer.uniqueIdentifier isEqualToString: playerIdentifier])
        player = candidatePlayer;
    }
  }
  
  if (!(self = [self initWithWorld: world player: player]))
    return nil;
  
  _autoconnect = [decoder decodeBoolForKey: @"autoconnect"];
  
  _textColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectOfClass: [NSData class]
                                                                            forKey: @"textColor"]];
  _backgroundColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectOfClass: [NSData class]
                                                                                  forKey: @"backgroundColor"]];
  _linkColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectOfClass: [NSData class]
                                                                            forKey: @"linkColor"]];
  
  if (version >= 4)
  {
    _font = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectOfClass: [NSData class]
                                                                         forKey: @"font"]];
    _systemTextColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectOfClass: [NSData class]
                                                                                    forKey: @"systemTextColor"]];
  }
  else
  {
    _font = [NSFont fontWithName: [decoder decodeObjectOfClass: [NSString class] forKey: @"fontName"]
                            size: [decoder decodeFloatForKey: @"fontSize"]];
    _systemTextColor = nil;
  }
  
  [self _startObservingUserDefaultsController];
  
  return self;
}

#pragma mark - Private methods

- (void) _startObservingUserDefaultsController
{
  NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [defaultsController addObserver: self
                       forKeyPath: [MUApplicationController keyPathForBackgroundColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [MUApplicationController keyPathForFont]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [MUApplicationController keyPathForLinkColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [MUApplicationController keyPathForSystemTextColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [MUApplicationController keyPathForTextColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
}

- (void) _stopObservingUserDefaultsController
{
  NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [defaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForBackgroundColor]];
  [defaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForFont]];
  [defaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForLinkColor]];
  [defaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForSystemTextColor]];
  [defaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForTextColor]];
}

@end
