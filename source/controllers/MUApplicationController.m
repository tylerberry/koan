//
// MUApplicationController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUApplicationController.h"

#import "CTBadge.h"
#import "FontNameToDisplayNameTransformer.h"
#import "JRSwizzle.h"
#import "NSObject (BetterHashing).h"

#import "MUAcknowledgementsController.h"
#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"
#import "MUPlayer.h"
#import "MUPreferencesController.h"
#import "MUProfileRegistry.h"
#import "MUProfilesWindowController.h"
#import "MUProxySettingsController.h"
#import "MUSocketFactory.h"
#import "MUWorld.h"
#import "MUWorldRegistry.h"

@interface MUApplicationController ()
{
  NSUInteger _unreadCount;
  CTBadge *_dockBadge;
  
  NSMutableArray *_connectionWindowControllers;
  MUAcknowledgementsController *_acknowledgementsController;
  MUConnectPanelController *_connectPanelController;
  MUProfilesWindowController *_profilesController;
  MUProxySettingsController *_proxySettingsController;
}

@property (readonly) BOOL _shouldPlayNotificationSound;

- (void) _colorPanelColorDidChange: (NSNotification *) notification;
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
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
  
  // Replace NSObject's -hash method with a better version via method swizzling.
  
  NSError *swizzleError = nil;
  [NSObject jr_swizzleMethod: @selector (hash) withMethod: @selector (betterHash) error: &swizzleError];
  
  if (swizzleError)
    NSLog (@"Error occurred trying to swizzle NSObject -hash to -betterHash: %@", swizzleError.description);
  
  NSValueTransformer *transformer = [[FontNameToDisplayNameTransformer alloc] init];
  [NSValueTransformer setValueTransformer: transformer forName: @"FontNameToDisplayNameTransformer"];
  
  defaults[MUPWorlds] = @[];
  //defaults[@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"] = @YES;
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  
  NSFont *fixedPitchFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  initialValues[MUPFontName] = fixedPitchFont.fontName;
  initialValues[MUPFontSize] = @(fixedPitchFont.pointSize);

  initialValues[MUPBackgroundColor] = [NSArchiver archivedDataWithRootObject: [NSColor blackColor]];
  initialValues[MUPLinkColor] = [NSArchiver archivedDataWithRootObject: [NSColor blueColor]];
  initialValues[MUPTextColor] = [NSArchiver archivedDataWithRootObject: [NSColor lightGrayColor]];
  initialValues[MUPVisitedLinkColor] = [NSArchiver archivedDataWithRootObject: [NSColor purpleColor]];
  initialValues[MUPPlaySounds] = @YES;
  initialValues[MUPPlayWhenActive] = @NO;
  initialValues[MUPSoundChoice] = @"Pop";
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: initialValues];
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
  NSFont *font = [NSFont fontWithName: [values valueForKey: MUPFontName]
                                 size: [[values valueForKey: MUPFontSize] floatValue]];
  
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
  
  [_acknowledgementsController showWindow: self];
}

- (IBAction) showConnectPanel: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    _connectPanelController = [[MUConnectPanelController alloc] init];
    _connectPanelController.delegate = self;
  });
  
  [_connectPanelController showWindow: self];
}

- (IBAction) showPreferencesWindow: (id) sender
{
  [preferencesController showPreferencesWindow: sender];
}

- (IBAction) showProfilesWindow: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _profilesController = [[MUProfilesWindowController alloc] init]; });
  
  [_profilesController showWindow: self];
}

- (IBAction) showProxySettings: (id) sender
{
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _proxySettingsController = [[MUProxySettingsController alloc] init]; });
  
  [_proxySettingsController showWindow: self];
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
  [preferencesController changeFont: sender];
}

#pragma mark - Private methods

@dynamic _shouldPlayNotificationSound;

- (void) _colorPanelColorDidChange: (NSNotification *) notification
{
  [preferencesController colorPanelColorDidChange];
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
  NSString *soundName = [[NSUserDefaults standardUserDefaults] stringForKey: MUPSoundChoice];
  if (soundName && soundName.length != 0)
    [[NSSound soundNamed: soundName] play];
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
                                           selector: @selector (_colorPanelColorDidChange:)
                                               name: NSColorPanelColorDidChangeNotification
                                             object: nil];
  
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
    [_dockBadge badgeApplicationDockIconWithValue: _unreadCount insetX: (float) 0.0 y: (float) 0.0];
}

- (void) _worldsDidChange: (NSNotification *) notification
{
  [self _rebuildConnectionsMenuWithAutoconnect: NO];
}

@end
