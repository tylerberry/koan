//
// MUApplicationController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUApplicationController.h"

#import "NSColor+ANSI.h"
#import "NSObject+BetterHashing.h"

#import "MUFontsAndColorsPreferencesViewController.h"
#import "MUGeneralPreferencesViewController.h"
#import "MULoggingPreferencesViewController.h"
#import "MUProxyPreferencesViewController.h"
#import "MUSoundsPreferencesViewController.h"

#import "MUAcknowledgementsWindowController.h"
#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"
#import "MUConnectionWindowControllerRegistry.h"
#import "MUPlayer.h"
#import "MUProfileRegistry.h"
#import "MUProfilesWindowController.h"
#import "MUProxySettings.h"
#import "MUWorld.h"
#import "MUWorldRegistry.h"

#import "JRSwizzle.h"
#import "MASPreferencesWindowController.h"

@interface MUApplicationController ()
{
  NSUInteger _unreadCount;
  
  NSSound *_cachedSound;
  
  MUAcknowledgementsWindowController *_acknowledgementsController;
  MUConnectPanelController *_connectPanelController;
  MASPreferencesWindowController *_preferencesController;
  MUProfilesWindowController *_profilesController;
}

@property (readonly) BOOL _shouldPlayNotificationSound;

+ (void) _initializeUserDefaults;

- (void) _openConnectionFromMenuItem: (id) sender;
- (void) _openConnectionWithWindowController: (MUConnectionWindowController *) controller;
- (void) _playNotificationSound;
- (void) _rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect;
- (void) _recursivelyConfirmClose: (BOOL) cont;
- (void) _updateApplicationBadge;
- (void) _updateCachedSound;
- (void) _worldsDidChange: (NSNotification *) notification;

@end

#pragma mark -

@implementation MUApplicationController

+ (void) initialize
{
  // Replace NSObject's -hash method with a better version via method swizzling.
  
  NSError *swizzleError = nil;
  [NSObject jr_swizzleMethod: @selector (hash) withMethod: @selector (betterHash) error: &swizzleError];
  
  if (swizzleError)
    NSLog (@"Error occurred trying to swizzle NSObject -hash to -betterHash: %@", swizzleError.description);
  
  [MUApplicationController _initializeUserDefaults];
  
  [NSFontManager sharedFontManager].action = @selector (changeProfileFont:);
}

- (void) awakeFromNib
{
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_worldsDidChange:)
                                               name: MUWorldsDidChangeNotification
                                             object: nil];
  
  // Initialize the cached sound and observe user defaults for any changes.
  
  [self _updateCachedSound];
  
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [userDefaultsController addObserver: self
                           forKeyPath: [MUApplicationController keyPathForSoundChoice]
                              options: NSKeyValueObservingOptionNew
                              context: NULL];
  
  [userDefaultsController addObserver: self
                           forKeyPath: [MUApplicationController keyPathForSoundVolume]
                              options: NSKeyValueObservingOptionNew
                              context: NULL];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [userDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForSoundChoice]];
  [userDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForSoundVolume]];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == [NSUserDefaultsController sharedUserDefaultsController])
  {
    if ([keyPath isEqualToString: [MUApplicationController keyPathForSoundChoice]]
        || [keyPath isEqualToString: [MUApplicationController keyPathForSoundVolume]])
    {
      [self _updateCachedSound];
      return;
    }
  }
  
  return [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

#pragma mark - Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSFont *font = [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPFont]];
  
  if (!font)
    font = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  [[NSFontManager sharedFontManager] setSelectedFont: font isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) connectToURL: (NSURL *) url
{
  if (!([url.scheme isEqualToString: @"telnet"] || [url.scheme isEqualToString: @"koan"]))
    return;
  
  MUWorld *world = [MUWorld worldWithHostname: url.host port: url.port forceTLS: NO];
  
  MUConnectionWindowControllerRegistry *registry = [MUConnectionWindowControllerRegistry defaultRegistry];
  
  [self _openConnectionWithWindowController: [registry controllerForWorld: world]];
}

- (IBAction) openBugsWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: MUKoanBugsURLString]];
}

- (IBAction) showAboutPanel: (id) sender;
{
  [NSApp orderFrontStandardAboutPanel: sender];
}

- (IBAction) showAcknowledgementsWindow: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _acknowledgementsController = [[MUAcknowledgementsWindowController alloc] init]; });
  
  [_acknowledgementsController showWindow: sender];
}

- (IBAction) showConnectPanel: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    _connectPanelController = [[MUConnectPanelController alloc] init];
    _connectPanelController.delegate = self;
  });
  
  [_connectPanelController showWindow: sender];
}

- (IBAction) showPreferencesWindow: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    NSArray *preferenceViewControllers = @[[[MUGeneralPreferencesViewController alloc] init],
    [[MUFontsAndColorsPreferencesViewController alloc] init],
    [[MUSoundsPreferencesViewController alloc] init],
    [[MULoggingPreferencesViewController alloc] init],
    [[MUProxyPreferencesViewController alloc] init]];
    
    _preferencesController = [[MASPreferencesWindowController alloc] initWithViewControllers: preferenceViewControllers
                                                                                       title: _(MULPreferencesWindowName)];
  });
  
  [_preferencesController showWindow: sender];
}

- (IBAction) showProfilesWindow: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    _profilesController = [[MUProfilesWindowController alloc] init];
    _profilesController.delegate = self;
  });
  
  [_profilesController showWindow: sender];
}

#pragma mark - NSApplicationDelegate protocol

- (BOOL) application: (NSApplication *) application openFile: (NSString *) string
{
  return NO;
}

- (void) applicationDidBecomeActive: (NSNotification *) notification
{
#if DEBUG
  if (getenv ("XCODE_RUNNING_TESTS"))
    return;
#endif
  
  _unreadCount = 0;
  [self _updateApplicationBadge];
}

- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
#if DEBUG
  if (getenv ("XCODE_RUNNING_TESTS"))
    return;
#endif
  
  [self _rebuildConnectionsMenuWithAutoconnect: YES];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *) sender
{
  return NO;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) application
{
  NSUInteger openConnections = [MUConnectionWindowControllerRegistry defaultRegistry].connectedCount;

  if (openConnections > 0)
  {
    NSAlert *alert;
    NSInteger choice = NSAlertDefaultReturn;
    NSString *title = [NSString stringWithFormat:
      (openConnections == 1 ? _(MULConfirmQuitTitleSingular)
                            : _(MULConfirmQuitTitlePlural)),
      openConnections];
  
    if (openConnections > 1)
    {
      alert = [NSAlert alertWithMessageText: title
                              defaultButton: _(MULConfirm)
                            alternateButton: _(MULCancel)
                                otherButton: _(MULQuitImmediately)
                  informativeTextWithFormat: _(MULConfirmQuitMessage)];
    
      choice = [alert runModal];
      
      if (choice == NSAlertAlternateReturn)
        return NSTerminateCancel;
    }
    
    if (choice == NSAlertDefaultReturn)
    {
      [self _recursivelyConfirmClose: YES];
      return NSTerminateLater;
    }
  }
  
  return NSTerminateNow;
}

- (void) applicationWillTerminate: (NSNotification *) notification
{
  [NSApp setApplicationIconImage: nil];
}

#pragma mark - MUConnectPanelControllerDelegate protocol

- (void) openConnectionForWorld: (MUWorld *) world
{
  MUConnectionWindowControllerRegistry *registry = [MUConnectionWindowControllerRegistry defaultRegistry];
  
  [self _openConnectionWithWindowController: [registry controllerForWorld: world]];
}

#pragma mark - MUConnectionWindowControllerDelegate protocol

- (void) connectionWindowControllerDidReceiveText: (NSNotification *) notification
{
  if (self._shouldPlayNotificationSound)
    [self _playNotificationSound];
  
  if (![NSApp isActive])
  {
    [NSApp requestUserAttention: NSInformationalRequest];
    _unreadCount++;
    [self _updateApplicationBadge];
  }
}

#pragma mark - MUProfilesWindowControllerDelegate protocol

- (void) openConnectionForProfile: (MUProfile *) profile
{
  MUConnectionWindowControllerRegistry *registry = [MUConnectionWindowControllerRegistry defaultRegistry];
  [self _openConnectionWithWindowController: [registry controllerForProfile: profile]];
}

#pragma mark - Private methods

@dynamic _shouldPlayNotificationSound;

+ (void) _initializeUserDefaults
{
  NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
  
  //initialValues[@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"] = @YES;
  
  initialValues[MUPAutomaticReconnect] = @YES;
  initialValues[MUPLimitAutomaticReconnect] = @YES;
  initialValues[MUPAutomaticReconnectCount] = @3;
  
  initialValues[MUPDropDuplicateLines] = @YES;
  initialValues[MUPDropDuplicateLinesCount] = @3;
  
  initialValues[MUPFont] = [NSArchiver archivedDataWithRootObject:
                            [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]]];
  initialValues[MUPDefaultFontChangeBehavior] = MUPDefaultFontChangeAsk;
  
  initialValues[MUPBackgroundColor] = [NSArchiver archivedDataWithRootObject: [NSColor blackColor]];
  initialValues[MUPLinkColor] = [NSArchiver archivedDataWithRootObject: [NSColor blueColor]];
  initialValues[MUPTextColor] = [NSArchiver archivedDataWithRootObject: [NSColor lightGrayColor]];
  initialValues[MUPSystemTextColor] = [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]];
  
  initialValues[MUPANSIBlackColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBlackColor]];
  initialValues[MUPANSIRedColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIRedColor]];
  initialValues[MUPANSIGreenColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIGreenColor]];
  initialValues[MUPANSIYellowColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIYellowColor]];
  initialValues[MUPANSIBlueColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBlueColor]];
  initialValues[MUPANSIMagentaColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIMagentaColor]];
  initialValues[MUPANSICyanColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSICyanColor]];
  initialValues[MUPANSIWhiteColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIWhiteColor]];
  
  initialValues[MUPANSIBrightBlackColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightBlackColor]];
  initialValues[MUPANSIBrightRedColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightRedColor]];
  initialValues[MUPANSIBrightGreenColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightGreenColor]];
  initialValues[MUPANSIBrightYellowColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightYellowColor]];
  initialValues[MUPANSIBrightBlueColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightBlueColor]];
  initialValues[MUPANSIBrightMagentaColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightMagentaColor]];
  initialValues[MUPANSIBrightCyanColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightCyanColor]];
  initialValues[MUPANSIBrightWhiteColor] = [NSArchiver archivedDataWithRootObject: [NSColor ANSIBrightWhiteColor]];
  
  initialValues[MUPDisplayBrightAsBold] = @NO;
  
  initialValues[MUPPlaySounds] = @YES;
  initialValues[MUPPlayWhenActive] = @NO;
  initialValues[MUPSoundChoice] = @"file://localhost/System/Library/Sounds/Pop.aiff";
  initialValues[MUPSoundVolume] = @1.0;
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: initialValues];
  
  initialValues[MUPWorlds] = [NSKeyedArchiver archivedDataWithRootObject: [NSMutableArray array]];
  initialValues[MUPProfiles] = [NSKeyedArchiver archivedDataWithRootObject: [NSMutableDictionary dictionary]];
  initialValues[MUPProfilesOutlineViewState] = [NSMutableArray array];
  
  NSString *documentsLogPath = [@"~/Documents/Koan Logs" stringByExpandingTildeInPath];
  BOOL fileIsDirectory = NO;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: documentsLogPath isDirectory: &fileIsDirectory]
      && fileIsDirectory)
  {
    NSURL *documentsLogURL = [NSURL fileURLWithPath: documentsLogPath];
    initialValues[MUPLogDirectoryURL] = documentsLogURL.absoluteString;
  }
  else
  {
    NSString *libraryLogPath = [@"~/Library/Logs/Koan" stringByExpandingTildeInPath];
    
    fileIsDirectory = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: libraryLogPath isDirectory: &fileIsDirectory]
        && fileIsDirectory)
    {
      NSURL *libraryLogURL = [NSURL fileURLWithPath: libraryLogPath];
      initialValues[MUPLogDirectoryURL] = libraryLogURL.absoluteString;
    }
    else
    {
      NSURL *documentsLogURL = [NSURL fileURLWithPath: documentsLogPath];
      initialValues[MUPLogDirectoryURL] = documentsLogURL.absoluteString;
    }
  }
  
  initialValues[MUPUseProxy] = MUPProxyNone;
  initialValues[MUPProxySettings] = [NSKeyedArchiver archivedDataWithRootObject: [[MUProxySettings alloc] init]];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: initialValues];
}

- (void) _openConnectionFromMenuItem: (id) sender
{
  MUProfile *profile = ((NSMenuItem *) sender).representedObject;
  
  MUConnectionWindowControllerRegistry *registry = [MUConnectionWindowControllerRegistry defaultRegistry];
  [self _openConnectionWithWindowController: [registry controllerForProfile: profile]];
}

- (void) _openConnectionWithWindowController: (MUConnectionWindowController *) controller
{
  controller.delegate = self;
  
  [controller showWindow: nil];

  if (!controller.connection.isConnectedOrConnecting)
    [controller connect: nil];
}

- (void) _playNotificationSound
{
  [_cachedSound performSelectorOnMainThread: @selector (play) withObject: nil waitUntilDone: NO];
}

- (void) _rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect
{
  MUWorldRegistry *worldRegistry = [MUWorldRegistry defaultRegistry];
  MUProfileRegistry *profileRegistry = [MUProfileRegistry defaultRegistry];
  
  for (NSInteger menuItemIndex = openConnectionMenu.numberOfItems - 1; menuItemIndex >= 0; menuItemIndex--)
  {
    [openConnectionMenu removeItemAtIndex: menuItemIndex];
  }
  
  BOOL didAutoconnect = NO;
  
  for (MUWorld *world in worldRegistry.worlds)
  {
    MUProfile *profile = [profileRegistry profileForWorld: world];
    NSMenuItem *worldItem = [[NSMenuItem alloc] init];
    NSMenu *worldMenu = [[NSMenu alloc] initWithTitle: world.name ? world.name : @""];
    NSMenuItem *connectItem = [[NSMenuItem alloc] initWithTitle: _(MULConnectWithoutLogin)
                                                         action: @selector (_openConnectionFromMenuItem:)
                                                  keyEquivalent: @""];
    
    connectItem.target = self;
    connectItem.representedObject = profile;
    
    if (autoconnect)
    {
      if (profile.autoconnect)
      {
        didAutoconnect = YES;
        [self _openConnectionFromMenuItem: connectItem];
      }
    }
    
    for (MUPlayer *player in world.children)
    {
      profile = [profileRegistry profileForWorld: world player: player];
      
      SEL action = @selector (_openConnectionFromMenuItem:);
      NSMenuItem *playerItem = [[NSMenuItem alloc] initWithTitle: player.name ? player.name : @""
                                                          action: action
                                                   keyEquivalent: @""];
      
      [playerItem bind: @"title" toObject: player withKeyPath: @"name" options: nil];
      playerItem.target = self;
      playerItem.representedObject = profile;
      
      if (autoconnect)
      {
        profile.world = world;
        profile.player = player;
        
        if (profile.autoconnect)
        {
          didAutoconnect = YES;
          [self _openConnectionFromMenuItem: playerItem];
        }
      }
      
      [worldMenu addItem: playerItem];
    }
    
    if (world.children.count > 0)
    {
      [worldMenu addItem: [NSMenuItem separatorItem]];
    }
    
    [worldMenu addItem: connectItem];
    
    worldItem.title = world.name ? world.name : @"";
    [worldItem bind: @"title" toObject: world withKeyPath: @"name" options: nil];
    worldItem.submenu = worldMenu;
    
    [openConnectionMenu addItem: worldItem];
  }
  
  if (autoconnect && !didAutoconnect)
    [self showProfilesWindow: self];
}

- (void) _recursivelyConfirmClose: (BOOL) cont
{
  if (cont)
  {
    for (MUConnectionWindowController *controller in [MUConnectionWindowControllerRegistry defaultRegistry].controllers)
    {
      if (controller.connection.isConnectedOrConnecting)
      {
        [controller confirmClose: @selector (_recursivelyConfirmClose:)];
        return;
      }
    }
  }
  
  [NSApp replyToApplicationShouldTerminate: cont];
}

- (BOOL) _shouldPlayNotificationSound
{
  return ([[NSUserDefaults standardUserDefaults] boolForKey: MUPPlaySounds]
          && (![NSApp isActive] || [[NSUserDefaults standardUserDefaults] boolForKey: MUPPlayWhenActive]));
}

- (void) _updateApplicationBadge
{
  if (_unreadCount == 0)
    [NSApp dockTile].badgeLabel = nil;
  else
    [NSApp dockTile].badgeLabel = [NSString stringWithFormat: @"%lu", _unreadCount];
}

- (void) _updateCachedSound
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSURL *soundURL = [NSURL URLWithString: [userDefaults objectForKey: MUPSoundChoice]];
  
  if (soundURL)
  {
    _cachedSound = [[NSSound alloc] initWithContentsOfURL: soundURL byReference: YES];
    _cachedSound.volume = [userDefaults floatForKey: MUPSoundVolume];
  }
}

- (void) _worldsDidChange: (NSNotification *) notification
{
  [self _rebuildConnectionsMenuWithAutoconnect: NO];
}

#pragma mark - User defaults key path string methods

+ (NSString *) keyPathForBackgroundColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPBackgroundColor]; });

  return keyPath;
}

+ (NSString *) keyPathForFont
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPFont]; });

  return keyPath;
}

+ (NSString *) keyPathForLinkColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPLinkColor]; });

  return keyPath;
}

+ (NSString *) keyPathForSystemTextColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPSystemTextColor]; });

  return keyPath;
}

+ (NSString *) keyPathForTextColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPTextColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBlackColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBlackColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIRedColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIRedColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIGreenColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIGreenColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIYellowColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIYellowColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBlueColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBlueColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIMagentaColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIMagentaColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSICyanColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSICyanColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIWhiteColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIWhiteColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightBlackColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightBlackColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightRedColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightRedColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightGreenColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightGreenColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightYellowColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightYellowColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightBlueColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightBlueColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightMagentaColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightMagentaColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightCyanColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightCyanColor]; });

  return keyPath;
}

+ (NSString *) keyPathForANSIBrightWhiteColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightWhiteColor]; });

  return keyPath;
}

+ (NSString *) keyPathForDisplayBrightAsBold
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;

  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPDisplayBrightAsBold]; });

  return keyPath;
}

+ (NSString *) keyPathForSoundChoice
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPSoundChoice]; });
  
  return keyPath;
}

+ (NSString *) keyPathForSoundVolume
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPSoundVolume]; });
  
  return keyPath;
}

@end
