//
// MUApplicationController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUApplicationController.h"

#import "NSColor (ANSI).h"
#import "NSObject (BetterHashing).h"

#import "MUAcknowledgementsController.h"
#import "MUFontsAndColorsPreferencesViewController.h"
#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"
#import "MUGeneralPreferencesViewController.h"
#import "MUPlayer.h"
#import "MUProfileRegistry.h"
#import "MUProfilesWindowController.h"
#import "MUProxyPreferencesViewController.h"
#import "MUProxySettings.h"
#import "MUSocketFactory.h"
#import "MUSoundsPreferencesViewController.h"
#import "MUWorld.h"
#import "MUWorldRegistry.h"

#import "CTBadge.h"
#import "JRSwizzle.h"
#import "MASPreferencesWindowController.h"

@interface MUApplicationController ()
{
  NSUInteger _unreadCount;
  CTBadge *_dockBadge;
  
  NSSound *_cachedSound;
  
  NSMutableArray *_connectionWindowControllers;
  MUAcknowledgementsController *_acknowledgementsController;
  MUConnectPanelController *_connectPanelController;
  MASPreferencesWindowController *_preferencesController;
  MUProfilesWindowController *_profilesController;
}

@property (readonly) BOOL _shouldPlayNotificationSound;

+ (void) _initializeUserDefaults;

- (void) _openConnectionFromMenuItem: (id) sender;
- (void) _openConnectionWithController: (MUConnectionWindowController *) controller;
- (void) _playNotificationSound;
- (void) _rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect;
- (void) _recursivelyConfirmClose: (BOOL) cont;
- (void) _updateApplicationBadge;
- (void) _updateCachedSound;
- (void) _worldsDidChange: (NSNotification *) notification;

#pragma mark - User defaults key path string methods

- (NSString *) _keyPathForSoundChoice;
- (NSString *) _keyPathForSoundVolume;

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
}

- (void) awakeFromNib
{
  _connectionWindowControllers = [[NSMutableArray alloc] init];
  _dockBadge = [CTBadge badgeWithColor: [NSColor blueColor] labelColor: [NSColor whiteColor]];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_worldsDidChange:)
                                               name: MUWorldsDidChangeNotification
                                             object: nil];
  
  // Initialize the cached sound and observe user defaults for any changes.
  
  [self _updateCachedSound];
  
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [userDefaultsController addObserver: self
                           forKeyPath: [self _keyPathForSoundChoice]
                              options: NSKeyValueObservingOptionNew
                              context: NULL];
  
  [userDefaultsController addObserver: self
                           forKeyPath: [self _keyPathForSoundVolume]
                              options: NSKeyValueObservingOptionNew
                              context: NULL];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [userDefaultsController removeObserver: self forKeyPath: [self _keyPathForSoundChoice]];
  [userDefaultsController removeObserver: self forKeyPath: [self _keyPathForSoundVolume]];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == [NSUserDefaultsController sharedUserDefaultsController])
  {
    if ([keyPath isEqualToString: [self _keyPathForSoundChoice]]
        || [keyPath isEqualToString: [self _keyPathForSoundVolume]])
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
  
  MUWorld *world = [MUWorld worldWithHostname: url.host port: url.port];
  
  MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithWorld: world];
  
  [self _openConnectionWithController: controller];
  
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
  
  dispatch_once (&predicate, ^{ _acknowledgementsController = [[MUAcknowledgementsController alloc] init]; });
  
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
  NSUInteger count = _connectionWindowControllers.count;
  NSUInteger openConnections = 0;
  
  while (count--)
  {
    MUConnectionWindowController *controller = _connectionWindowControllers[count];
    if (controller && controller.isConnectedOrConnecting)
      openConnections++;
  }
  
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
  MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithWorld: world];
  
  [self _openConnectionWithController: controller];
}

#pragma mark - MUConnectionWindowControllerDelegate protocol

- (void) connectionWindowControllerWillClose: (NSNotification *) notification
{
  MUConnectionWindowController *controller = notification.object;
  
  [_connectionWindowControllers removeObject: controller];
}

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
  [self _openConnectionWithController: [[MUConnectionWindowController alloc] initWithProfile: profile]];
}

#pragma mark - Responder chain methods

- (IBAction) changeFont: (id) sender
{
  [_preferencesController changeFont: sender];
}

#pragma mark - Private methods

@dynamic _shouldPlayNotificationSound;

+ (void) _initializeUserDefaults
{
  NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
  
  //initialValues[@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"] = @YES;
  
  initialValues[MUPFont] = [NSArchiver archivedDataWithRootObject:
                            [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]]];
  
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
  initialValues[MUPSoundVolume] = @(1.0);
  
  initialValues[MUPUseProxy] = @(0);
  initialValues[MUPProxySettings] = [NSKeyedArchiver archivedDataWithRootObject: [[MUProxySettings alloc] init]];
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: initialValues];
  
  initialValues[MUPWorlds] = [NSKeyedArchiver archivedDataWithRootObject: [NSMutableArray array]];
  initialValues[MUPProfiles] = [NSKeyedArchiver archivedDataWithRootObject: [NSMutableDictionary dictionary]];
  initialValues[MUPProfilesOutlineViewState] = [NSMutableArray array];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: initialValues];
}

- (void) _openConnectionFromMenuItem: (id) sender
{
  MUConnectionWindowController *controller;
  MUProfile *profile = ((NSMenuItem *) sender).representedObject;
  controller = [[MUConnectionWindowController alloc] initWithProfile: profile];
  
  [self _openConnectionWithController: controller];
}

- (void) _openConnectionWithController: (MUConnectionWindowController *) controller
{
  controller.delegate = self;
  
  [_connectionWindowControllers addObject: controller];
  [controller showWindow: self];
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
      profile.world = world;
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
    [worldItem setTitle: world.name ? world.name : @""];
    [worldItem bind: @"title" toObject: world withKeyPath: @"name" options: nil];
    [worldItem setSubmenu: worldMenu];
    [openConnectionMenu addItem: worldItem];
  }
  
  if (autoconnect && !didAutoconnect)
    [self showProfilesWindow: self];
}

- (void) _recursivelyConfirmClose: (BOOL) cont
{
  if (cont)
  {
    for (MUConnectionWindowController *controller in _connectionWindowControllers)
    {
      if (controller.isConnectedOrConnecting)
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
    [NSApp setApplicationIconImage: nil];
  else
    [_dockBadge badgeApplicationDockIconWithValue: _unreadCount insetX: 0.0 y: 0.0];
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

- (NSString *) _keyPathForSoundChoice
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPSoundChoice]; });
  
  return keyPath;
}

- (NSString *) _keyPathForSoundVolume
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPSoundVolume]; });
  
  return keyPath;
}

@end
