//
// MUApplicationController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUApplicationController.h"

#import "NSObject (BetterHashing).h"

#import "MUAcknowledgementsController.h"
#import "MUFontsAndColorsPreferencesViewController.h"
#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"
#import "MUPlayer.h"
#import "MUProfileRegistry.h"
#import "MUProfilesWindowController.h"
#import "MUProxyPreferencesViewController.h"
#import "MUProxySettingsController.h"
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
  
  NSMutableArray *_connectionWindowControllers;
  MUAcknowledgementsController *_acknowledgementsController;
  MUConnectPanelController *_connectPanelController;
  MASPreferencesWindowController *_preferencesController;
  MUProfilesWindowController *_profilesController;
  MUProxySettingsController *_proxySettingsController;
}

@property (readonly) BOOL _shouldPlayNotificationSound;

+ (void) _initializeUserDefaults;

- (void) _openConnectionFromMenuItem: (id) sender;
- (void) _openConnectionWithController: (MUConnectionWindowController *) controller;
- (void) _playNotificationSound;
- (void) _rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect;
- (void) _recursivelyConfirmClose: (BOOL) cont;
- (void) _registerForNotifications;
- (void) _updateApplicationBadge;
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
}

- (void) awakeFromNib
{
  _connectionWindowControllers = [[NSMutableArray alloc] init];
  
  [self _registerForNotifications];
  
  _dockBadge = [CTBadge badgeWithColor: [NSColor blueColor] labelColor: [NSColor whiteColor]];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
}

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
  if (item.action == @selector (toggleUseProxy:))
    [item setState: ([[MUSocketFactory defaultFactory] useProxy] ? NSOnState : NSOffState)];
  return YES;
}

#pragma mark - Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
  NSFont *font = [NSUnarchiver unarchiveObjectWithData: [values valueForKey: MUPFont]];
  
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
    NSArray *preferenceViewControllers = [NSArray arrayWithObjects:
                                          [[MUFontsAndColorsPreferencesViewController alloc] init],
                                          [[MUSoundsPreferencesViewController alloc] init],
                                          [[MUProxyPreferencesViewController alloc] init], nil];
    _preferencesController = [[MASPreferencesWindowController alloc] initWithViewControllers: preferenceViewControllers
                                                                                       title: _(MULPreferencesWindowName)];
  });
  
  [_preferencesController showWindow: sender];
}

- (IBAction) showProfilesWindow: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _profilesController = [[MUProfilesWindowController alloc] init]; });
  
  [_profilesController showWindow: sender];
}

- (IBAction) showProxySettings: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _proxySettingsController = [[MUProxySettingsController alloc] init]; });
  
  [_proxySettingsController showWindow: sender];
}

- (IBAction) toggleUseProxy: (id) sender
{
  [[MUSocketFactory defaultFactory] toggleUseProxy];
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
  
  [[MUSocketFactory defaultFactory] saveProxySettings];
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
  initialValues[MUPPlaySounds] = @YES;
  initialValues[MUPPlayWhenActive] = @NO;
  initialValues[MUPSoundChoice] = @"file://localhost/System/Library/Sounds/Pop.aiff";
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: initialValues];
  
  initialValues[MUPWorlds] = @[];
  
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
  [controller setDelegate: self];
  
  [_connectionWindowControllers addObject: controller];
  [controller showWindow: self];
  [controller connect: nil];
}

- (void) _playNotificationSound
{
  NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  NSURL *soundURL = [NSURL URLWithString: [userDefaultsController.values valueForKey: MUPSoundChoice]];

  if (soundURL)
  {
    NSSound *sound = [[NSSound alloc] initWithContentsOfURL: soundURL byReference: YES];
    
    [sound performSelectorOnMainThread: @selector (play) withObject: nil waitUntilDone: NO];
  }
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

- (void) _registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_worldsDidChange:)
                                               name: MUWorldsDidChangeNotification
                                             object: nil];
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

- (void) _worldsDidChange: (NSNotification *) notification
{
  [self _rebuildConnectionsMenuWithAutoconnect: NO];
}

@end
