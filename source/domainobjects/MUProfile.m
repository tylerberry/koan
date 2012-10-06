//
// MUProfile.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUCodingService.h"
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

@synthesize world, player, autoconnect;
@dynamic hostname, loginString, uniqueIdentifier, windowTitle;
@dynamic effectiveBackgroundColor, effectiveFont, effectiveFontDisplayName, effectiveLinkColor, effectiveTextColor;

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) key
{
  static NSArray *keyArray;
  
  if (!keyArray)
  {
  	keyArray = [NSArray arrayWithObjects:
  		@"effectiveFont",
  		@"effectiveFontDisplayName",
      @"effectiveTextColor",
  		@"effectiveBackgroundColor",
  		@"effectiveLinkColor",
  		@"effectiveVisitedLinkColor",
  		nil];
  }
  
  if ([keyArray containsObject: key])
  	return NO;
  else
  	return YES;
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
  [self setFont: newFont];
  [self setTextColor: newTextColor];
  [self setBackgroundColor: newBackgroundColor];
  [self setLinkColor: newLinkColor];
  [self setVisitedLinkColor: newVisitedLinkColor];
  
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

#pragma mark - Accessors

- (NSFont *) font
{
  return font;
}

- (void) setFont: (NSFont *) newFont
{
  if ([font isEqual: newFont])
    return;
  
  [self willChangeValueForKey: @"effectiveFont"];
  [self willChangeValueForKey: @"effectiveFontDisplayName"];
  font = [newFont copy];
  [self didChangeValueForKey: @"effectiveFont"];
  [self didChangeValueForKey: @"effectiveFontDisplayName"];
}

- (NSColor *) textColor
{
  return textColor;
}

- (void) setTextColor: (NSColor *) newTextColor
{
  if ([textColor isEqual: newTextColor])
    return;
  
  [self willChangeValueForKey: @"effectiveTextColor"];
  textColor = [newTextColor copy];
  [self didChangeValueForKey: @"effectiveTextColor"];
}

- (NSColor *) backgroundColor
{
  return backgroundColor;
}

- (void) setBackgroundColor: (NSColor *) newBackgroundColor
{
  if ([backgroundColor isEqual: newBackgroundColor])
    return;
  
  [self willChangeValueForKey: @"effectiveBackgroundColor"];
  backgroundColor = [newBackgroundColor copy];
  [self didChangeValueForKey: @"effectiveBackgroundColor"];
}

- (NSColor *) linkColor
{
  return linkColor;
}

- (void) setLinkColor: (NSColor *) newLinkColor
{
  if ([linkColor isEqual: newLinkColor])
    return;
  
  [self willChangeValueForKey: @"effectiveLinkColor"];
  linkColor = [newLinkColor copy];
  [self didChangeValueForKey: @"effectiveLinkColor"];
}

- (NSColor *) visitedLinkColor
{
  return visitedLinkColor;
}

- (void) setVisitedLinkColor: (NSColor *) newVisitedLinkColor
{
  if ([visitedLinkColor isEqual: newVisitedLinkColor])
    return;
  
  [self willChangeValueForKey: @"effectiveVisitedLinkColor"];
  visitedLinkColor = [newVisitedLinkColor copy];
  [self didChangeValueForKey: @"effectiveVisitedLinkColor"];
}

#pragma mark - Accessors for bindings

- (NSColor *) effectiveBackgroundColor
{
  if (backgroundColor)
  	return backgroundColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPBackgroundColor]];
  }
}

- (NSFont *) effectiveFont
{
  if (font)
  	return font;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	NSString *fontName = [defaults.values valueForKey: MUPFontName];
  	float fontSize = ((NSNumber *) [defaults.values valueForKey: MUPFontSize]).floatValue;
  	
  	return [NSFont fontWithName: fontName size: fontSize];
  }
}

- (NSString *) effectiveFontDisplayName
{
  if (font)
  	return font.fullDisplayName;
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
  if (linkColor)
  	return linkColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPLinkColor]];
  }
}

- (NSColor *) effectiveTextColor
{
  if (textColor)
  	return textColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPTextColor]];
  }
}

- (NSColor *) effectiveVisitedLinkColor
{
  if (visitedLinkColor)
  	return visitedLinkColor;
  else
  {
  	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	
  	return [NSUnarchiver unarchiveObjectWithData: [defaults.values valueForKey: MUPVisitedLinkColor]];
  }
}

#pragma mark - Actions

- (MUMUDConnection *) createNewTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [world newTelnetConnectionWithDelegate: delegate];
}

- (MUFilter *) createLogger
{
  if (player)
    return [MUTextLogger filterWithWorld: world player: player];
  else
    return [MUTextLogger filterWithWorld: world];
}

- (BOOL) hasLoginInformation
{
  return self.loginString != nil;
}

#pragma mark - Property method implementations

- (NSString *) hostname
{
  return world.hostname;
}

- (NSString *) loginString
{
  if (player)
    return player.loginString;
  else
    return nil;
}

- (NSString *) uniqueIdentifier
{
  NSString *identifier = nil;
  if (player)
  {
    // FIXME:  Consider offloading the generation of a unique name for the player on MUPlayer.
    identifier = [NSString stringWithFormat: @"%@;%@", world.uniqueIdentifier, player.uniqueIdentifier];
  }
  else
  {
    identifier = world.uniqueIdentifier;
  }
  return identifier;
}

- (NSString *) windowTitle
{
  return (player ? player.windowTitle : world.windowTitle);
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
  if (!backgroundColor)
  {
  	[self willChangeValueForKey: @"effectiveBackgroundColor"];
  	[self didChangeValueForKey: @"effectiveBackgroundColor"];
  }
}

- (void) globalFontDidChange: (NSNotification *) notification
{
  if (!font)
  {
  	[self willChangeValueForKey: @"effectiveFont"];
  	[self willChangeValueForKey: @"effectiveFontDisplayName"];
  	[self didChangeValueForKey: @"effectiveFont"];
  	[self didChangeValueForKey: @"effectiveFontDisplayName"];
  }
}

- (void) globalLinkColorDidChange: (NSNotification *) notification
{
  if (!linkColor)
  {
  	[self willChangeValueForKey: @"effectiveLinkColor"];
  	[self didChangeValueForKey: @"effectiveLinkColor"];
  }
}

- (void) globalTextColorDidChange: (NSNotification *) notification
{
  if (!textColor)
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
