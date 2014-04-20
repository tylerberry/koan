//
// MUProfile.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfile.h"
#import "MUTextLogger.h"

#import "MUWorldRegistry.h"

static const int32_t currentProfileVersion = 4;

@interface MUProfile ()

- (NSString *) _keyPathForBackgroundColor;
- (NSString *) _keyPathForFont;
- (NSString *) _keyPathForLinkColor;
- (NSString *) _keyPathForTextColor;

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

+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
{
  return [[self alloc] initWithWorld: newWorld
                              player: newPlayer];
}

+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld
{
  return [[self alloc] initWithWorld: newWorld];
}

- (id) initWithWorld: (MUWorld *) newWorld
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

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
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

- (id) initWithWorld: (MUWorld *) newWorld
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
    if ([keyPath isEqualToString: [self _keyPathForBackgroundColor]])
    {
      if (!self.backgroundColor)
      {
        [self willChangeValueForKey: @"effectiveBackgroundColor"];
        [self didChangeValueForKey: @"effectiveBackgroundColor"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForFont]])
    {
      if (!self.font)
      {
        [self willChangeValueForKey: @"effectiveFont"];
        [self didChangeValueForKey: @"effectiveFont"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForLinkColor]])
    {
      if (!self.linkColor)
      {
        [self willChangeValueForKey: @"effectiveLinkColor"];
        [self didChangeValueForKey: @"effectiveLinkColor"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForSystemTextColor]])
    {
      if (!self.systemTextColor)
      {
        [self willChangeValueForKey: @"effectiveSystemTextColor"];
        [self didChangeValueForKey: @"effectiveSystemTextColor"];
      }
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForTextColor]])
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

- (MUMUDConnection *) createNewTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [self.world newTelnetConnectionWithDelegate: delegate];
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

#pragma mark - NSCoding protocol

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

- (id) initWithCoder: (NSCoder *) decoder
{
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  if (version < 3) // Versions prior to 3 did not track world or player identifiers and are useless.
    return nil;
  
  NSString *worldIdentifier = [decoder decodeObjectForKey: @"worldIdentifier"];
  MUWorld *world = [[MUWorldRegistry defaultRegistry] worldForUniqueIdentifier: worldIdentifier];
  
  NSString *playerIdentifier = [decoder decodeObjectForKey: @"playerIdentifier"];
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
  
  _textColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"textColor"]];
  _backgroundColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"backgroundColor"]];
  _linkColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"linkColor"]];
  
  if (version >= 4)
  {
    _font = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"font"]];
    _systemTextColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"systemTextColor"]];
  }
  else
  {
    _font = [NSFont fontWithName: [decoder decodeObjectForKey: @"fontName"]
                            size: [decoder decodeFloatForKey: @"fontSize"]];
    _systemTextColor = nil;
  }
  
  [self _startObservingUserDefaultsController];
  
  return self;
}

#pragma mark - Private methods

- (NSString *) _keyPathForBackgroundColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPBackgroundColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForFont
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPFont]; });
  
  return keyPath;
}

- (NSString *) _keyPathForLinkColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPLinkColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForSystemTextColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPSystemTextColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForTextColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPTextColor]; });
  
  return keyPath;
}

- (void) _startObservingUserDefaultsController
{
  NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [defaultsController addObserver: self
                       forKeyPath: [self _keyPathForBackgroundColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [self _keyPathForFont]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [self _keyPathForLinkColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [self _keyPathForSystemTextColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
  
  [defaultsController addObserver: self
                       forKeyPath: [self _keyPathForTextColor]
                          options: NSKeyValueObservingOptionNew
                          context: NULL];
}

- (void) _stopObservingUserDefaultsController
{
  NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [defaultsController removeObserver: self forKeyPath: [self _keyPathForBackgroundColor]];
  [defaultsController removeObserver: self forKeyPath: [self _keyPathForFont]];
  [defaultsController removeObserver: self forKeyPath: [self _keyPathForLinkColor]];
  [defaultsController removeObserver: self forKeyPath: [self _keyPathForSystemTextColor]];
  [defaultsController removeObserver: self forKeyPath: [self _keyPathForTextColor]];
}

@end
