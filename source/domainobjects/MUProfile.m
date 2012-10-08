//
// MUProfile.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfile.h"
#import "MUTextLogger.h"

static const int32_t currentProfileVersion = 2;

@interface MUProfile ()

- (void) globalBackgroundColorDidChange: (NSNotification *) notification;
- (void) globalFontDidChange: (NSNotification *) notification;
- (void) globalLinkColorDidChange: (NSNotification *) notification;
- (void) globalTextColorDidChange: (NSNotification *) notification;
- (void) registerForNotifications;

@end

#pragma mark -

@implementation MUProfile

@synthesize font, backgroundColor, linkColor, textColor, visitedLinkColor;
@synthesize world, player, autoconnect;
@dynamic effectiveBackgroundColor, effectiveFont, effectiveFontDisplayName, effectiveLinkColor, effectiveTextColor;
@dynamic hasLoginInformation, hostname, loginString, uniqueIdentifier, windowTitle;

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) key
{
  static NSArray *keyArray;
  
  if (!keyArray)
  {
  	keyArray = @[@"effectiveFont", @"effectiveFontDisplayName", @"effectiveTextColor", @"effectiveBackgroundColor",
    @"effectiveLinkColor", @"effectiveVisitedLinkColor"];
  }
  
  if ([keyArray containsObject: key])
  	return NO;
  else
  	return [super automaticallyNotifiesObserversForKey: key];
}

+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *) key
{
  NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
  
  if ([key isEqualToString: @"effectiveFont"] || [key isEqualToString: @"effectiveFontDisplayName"])
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
  else if ([key isEqualToString: @"effectiveTextColor"])
  {
    keyPaths = [keyPaths setByAddingObject: @"textColor"];
  }
  else if ([key isEqualToString: @"effectiveVisitedLinkColor"])
  {
    keyPaths = [keyPaths setByAddingObject: @"visitedLinkColor"];
  }
  
  return keyPaths;
}

+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld
                          player: (MUPlayer *) newPlayer
                     autoconnect: (BOOL) newAutoconnect
{
  return [[self alloc] initWithWorld: newWorld
                              player: newPlayer
                         autoconnect: newAutoconnect];
}

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
  				 textColor: (NSColor *) newTextColor
  	 backgroundColor: (NSColor *) newBackgroundColor
  				 linkColor: (NSColor *) newLinkColor
  	visitedLinkColor: (NSColor *) newVisitedLinkColor
{
  if (!(self = [super init]))
    return nil;
  
  world = newWorld;
  player = newPlayer;
  autoconnect = newAutoconnect;
  font = newFont;
  textColor = [newTextColor copy];
  backgroundColor = [newBackgroundColor copy];
  linkColor = [newLinkColor copy];
  visitedLinkColor = [newVisitedLinkColor copy];
  
  [self registerForNotifications];
  
  return self;
}

- (id) initWithWorld: (MUWorld *) newWorld
              player: (MUPlayer *) newPlayer
         autoconnect: (BOOL) newAutoconnect
{
  return [self initWithWorld: newWorld
  										player: newPlayer
  							 autoconnect: newAutoconnect
  											font: nil
  								 textColor: nil
  					 backgroundColor: nil
  								 linkColor: nil
  					visitedLinkColor: nil];
}

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
{
  return [self initWithWorld: newWorld
                      player: newPlayer
                 autoconnect: NO];
}

- (id) initWithWorld: (MUWorld *) newWorld
{
  return [self initWithWorld: newWorld player: nil];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
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
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPBackgroundColor]];
  }
}

- (NSFont *) effectiveFont
{
  if (self.font)
  	return self.font;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	NSString *fontName = [defaults.values valueForKey: MUPFontName];
  	CGFloat fontSize = ((NSNumber *) [defaults.values valueForKey: MUPFontSize]).floatValue;
  	
  	return [NSFont fontWithName: fontName size: fontSize];
  }
}

- (NSString *) effectiveFontDisplayName
{
  if (self.font)
  	return self.font.fullDisplayName;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	NSString *fontName = [defaults.values valueForKey: MUPFontName];
  	NSNumber *fontSize = [defaults.values valueForKey: MUPFontSize];
  	
  	return [NSFont fontWithName: fontName size: fontSize.floatValue].fullDisplayName;
  }
}

- (NSColor *) effectiveLinkColor
{
  if (self.linkColor)
  	return self.linkColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPLinkColor]];
  }
}

- (NSColor *) effectiveTextColor
{
  if (self.textColor)
  	return self.textColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPTextColor]];
  }
}

- (NSColor *) effectiveVisitedLinkColor
{
  if (self.visitedLinkColor)
  	return self.visitedLinkColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPVisitedLinkColor]];
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
  NSString *identifier = nil;
  if (self.player)
  {
    // FIXME:  Consider offloading the generation of a unique name for the player on MUPlayer.
    identifier = [NSString stringWithFormat: @"%@;%@", self.world.uniqueIdentifier, self.player.uniqueIdentifier];
  }
  else
  {
    identifier = self.world.uniqueIdentifier;
  }
  return identifier;
}

- (NSString *) windowTitle
{
  return (self.player ? self.player.windowTitle : self.world.windowTitle);
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [encoder encodeInt32: currentProfileVersion forKey: @"version"];
  [encoder encodeBool: self.autoconnect forKey: @"autoconnect"];
  [encoder encodeObject: self.font.fontName forKey: @"fontName"];
  [encoder encodeFloat: (float) self.font.pointSize forKey: @"fontSize"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.textColor] forKey: @"textColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.backgroundColor] forKey: @"backgroundColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.linkColor] forKey: @"linkColor"];
  [encoder encodeObject: [NSArchiver archivedDataWithRootObject: self.visitedLinkColor] forKey: @"visitedLinkColor"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
  int32_t version = [decoder decodeInt32ForKey: @"version"];
  
  self.autoconnect = [decoder decodeBoolForKey: @"autoconnect"];
  
  if (version >= 2)
  {
  	self.font = [NSFont fontWithName: [decoder decodeObjectForKey: @"fontName"]
                                size: [decoder decodeFloatForKey: @"fontSize"]];
  	self.textColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"textColor"]];
  	self.backgroundColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"backgroundColor"]];
  	self.linkColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"linkColor"]];
  	self.visitedLinkColor = [NSUnarchiver unarchiveObjectWithData: [decoder decodeObjectForKey: @"visitedLinkColor"]];
  }
  
  [self registerForNotifications];
  
  return self;
}

#pragma mark - Private methods

- (void) globalBackgroundColorDidChange: (NSNotification *) notification
{
  if (!self.backgroundColor)
  {
  	[self willChangeValueForKey: @"effectiveBackgroundColor"];
  	[self didChangeValueForKey: @"effectiveBackgroundColor"];
  }
}

- (void) globalFontDidChange: (NSNotification *) notification
{
  if (!self.font)
  {
  	[self willChangeValueForKey: @"effectiveFont"];
  	[self willChangeValueForKey: @"effectiveFontDisplayName"];
  	[self didChangeValueForKey: @"effectiveFont"];
  	[self didChangeValueForKey: @"effectiveFontDisplayName"];
  }
}

- (void) globalLinkColorDidChange: (NSNotification *) notification
{
  if (!self.linkColor)
  {
  	[self willChangeValueForKey: @"effectiveLinkColor"];
  	[self didChangeValueForKey: @"effectiveLinkColor"];
  }
}

- (void) globalTextColorDidChange: (NSNotification *) notification
{
  if (!self.textColor)
  {
  	[self willChangeValueForKey: @"effectiveTextColor"];
  	[self didChangeValueForKey: @"effectiveTextColor"];
  }
}

- (void) registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalBackgroundColorDidChange:)
  																						 name: MUGlobalBackgroundColorDidChangeNotification
  																					 object: nil];
  	
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalFontDidChange:)
  																						 name: MUGlobalFontDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalLinkColorDidChange:)
  																						 name: MUGlobalLinkColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalTextColorDidChange:)
  																						 name: MUGlobalTextColorDidChangeNotification
  																					 object: nil];
}

@end
