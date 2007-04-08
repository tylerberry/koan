//
// MUApplicationController.m
//
// Copyright (c) 2007 3James Software.
//

#import "FontNameToDisplayNameTransformer.h"
#import "J3PortFormatter.h"
#import "MUApplicationController.h"
#import "MUConnectionWindowController.h"
#import "MUGrowlService.h"
#import "MUPlayer.h"
#import "MUPreferencesController.h"
#import "MUProfilesController.h"
#import "MUProxySettingsController.h"
#import "MUServices.h"
#import "J3SocketFactory.h"
#import "MUWorld.h"

@interface MUApplicationController (Private)

- (IBAction) changeFont: (id) sender;
- (void) colorPanelColorDidChange: (NSNotification *) notification;
- (IBAction) openConnection: (id) sender;
- (void) openConnectionWithController: (MUConnectionWindowController *) controller;
- (void) playNotificationSound;
- (void) rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect;
- (void) recursivelyConfirmClose: (BOOL) cont;
- (BOOL) shouldPlayNotificationSound;
- (void) updateApplicationBadge;
- (void) worldsDidChange: (NSNotification *) notification;

@end

#pragma mark -

@implementation MUApplicationController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
  NSValueTransformer *transformer = [[FontNameToDisplayNameTransformer alloc] init];
  NSFont *fixedPitchFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  [NSValueTransformer setValueTransformer: transformer forName: @"FontNameToDisplayNameTransformer"];
  
  [defaults setObject: [NSArray array] forKey: MUPWorlds];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor blackColor]] forKey: MUPBackgroundColor];
  [initialValues setObject: [fixedPitchFont fontName] forKey: MUPFontName];
  [initialValues setObject: [NSNumber numberWithFloat: [fixedPitchFont pointSize]] forKey: MUPFontSize];
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor blueColor]] forKey: MUPLinkColor];
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor lightGrayColor]] forKey: MUPTextColor];
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor purpleColor]] forKey: MUPVisitedLinkColor];
  [initialValues setObject: [NSNumber numberWithBool: YES] forKey: MUPPlaySounds];
  [initialValues setObject: [NSNumber numberWithBool: NO] forKey: MUPPlayWhenActive];
  [initialValues setObject: @"Blow" forKey: MUPSoundChoice];
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: initialValues];
  
  [MUGrowlService defaultGrowlService];
}

- (void) awakeFromNib
{
  J3PortFormatter *newConnectionPortFormatter = [[[J3PortFormatter alloc] init] autorelease];
  
  [MUServices profileRegistry];
  [MUServices worldRegistry];
  
  connectionWindowControllers = [[NSMutableArray alloc] init];
  
  [self rebuildConnectionsMenuWithAutoconnect: YES];
  
  [newConnectionPortField setFormatter: newConnectionPortFormatter];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (colorPanelColorDidChange:)
                                               name: NSColorPanelColorDidChangeNotification
                                             object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (worldsDidChange:)
                                               name: MUWorldsDidChangeNotification
                                             object: nil];
  
  unreadCount = 0;
  [self updateApplicationBadge];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  [connectionWindowControllers release];
  [profilesController release];
  [proxySettingsController release];
  [super dealloc];
}

- (BOOL) validateMenuItem: (id <NSMenuItem>) anItem
{
  if ([anItem isEqual: useProxyMenuItem])
    [useProxyMenuItem setState: ([[J3SocketFactory defaultFactory] useProxy] ? NSOnState : NSOffState)];
  return YES;
}

#pragma mark -
#pragma mark Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
  NSFont *font = [NSFont fontWithName: [values valueForKey: MUPFontName]
                                 size: [[values valueForKey: MUPFontSize] floatValue]];
  
  if (!font)
    font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  
  [[NSFontManager sharedFontManager] setSelectedFont: font isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) connectToURL: (NSURL *) url
{
  if (!([[url scheme] isEqualToString: @"telnet"]
        || [[url scheme] isEqualToString: @"koan"]))
    return;
  
  MUWorld *world = [MUWorld worldWithName: [url host]
  											hostname: [url host]
  													port: [url port]
  													 URL: @""
  											 players: nil];
  
  MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithWorld: world];
  
  [self openConnectionWithController: controller];
  
  [controller release];
}

- (IBAction) connectUsingPanelInformation: (id) sender
{
  MUWorld *world = [MUWorld worldWithName: [newConnectionHostnameField stringValue]
  															 hostname: [newConnectionHostnameField stringValue]
  																	 port: [NSNumber numberWithInt: [newConnectionPortField intValue]]
  																		URL: @""
  																players: nil];
  
  if ([newConnectionSaveWorldButton state] == NSOnState)
  	[[MUServices worldRegistry] insertObject: world inWorldsAtIndex: [[MUServices worldRegistry] count]];
  
  MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithWorld: world];
  
  [self openConnectionWithController: controller];
  [newConnectionPanel close];
  
  [controller release];
}

- (IBAction) openBugsWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://svn.thoughtlocker.net/trac/koan/"]];
}

- (IBAction) openNewConnectionPanel: (id) sender
{
  [newConnectionHostnameField setObjectValue: nil];
  [newConnectionPortField setObjectValue: nil];
  [newConnectionSaveWorldButton setState: NSOffState];
  [newConnectionPanel makeFirstResponder: newConnectionHostnameField];
  [newConnectionPanel makeKeyAndOrderFront: self];
}

- (IBAction) showPreferencesPanel: (id) sender
{
  [preferencesController showPreferencesPanel: sender];
}

- (IBAction) showProfilesPanel: (id) sender
{
  if (!profilesController)
    profilesController = [[MUProfilesController alloc] init];
  if (profilesController)
    [profilesController showWindow: self];
}

- (IBAction) showProxySettings: (id) sender
{
  if (!proxySettingsController)
    proxySettingsController = [[MUProxySettingsController alloc] init];
  if (proxySettingsController)
    [proxySettingsController showWindow: self];
}

- (IBAction) toggleUseProxy: (id) sender
{
  [[J3SocketFactory defaultFactory] toggleUseProxy];
}

#pragma mark -
#pragma mark NSApplication delegate

- (void) applicationDidBecomeActive: (NSNotification *) notification
{
  unreadCount = 0;
  [self updateApplicationBadge];
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) application
{
  unsigned count = [connectionWindowControllers count];
  unsigned openConnections = 0;
  
  while (count--)
  {
    MUConnectionWindowController *controller = [connectionWindowControllers objectAtIndex: count];
    if (controller && [controller isConnected])
      openConnections++;
  }
  
  if (openConnections > 0)
  {
    NSAlert *alert;
    int choice = NSAlertDefaultReturn;
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
      [self recursivelyConfirmClose: YES];
      return NSTerminateLater;
    }
  }
  
  return NSTerminateNow;
}

- (void) applicationWillTerminate: (NSNotification *) notification
{
  unreadCount = 0;
  [self updateApplicationBadge];
  
  [[MUServices worldRegistry] saveWorlds];
  [[MUServices profileRegistry] saveProfiles];
  [[J3SocketFactory defaultFactory] saveProxySettings];
}

#pragma mark -
#pragma mark MUConnectionWindowController delegate

- (void) connectionWindowControllerWillClose: (NSNotification *) notification
{
  MUConnectionWindowController *controller = [notification object];
  
  [controller retain];
  [connectionWindowControllers removeObject: controller];
  [controller autorelease];
}

- (void) connectionWindowControllerDidReceiveText: (NSNotification *) notification
{
  if ([self shouldPlayNotificationSound])
    [self playNotificationSound];
  if (![NSApp isActive])
  {
    [NSApp requestUserAttention: NSInformationalRequest];
    unreadCount++;
    [self updateApplicationBadge];
  }
}

@end

#pragma mark -

@implementation MUApplicationController (Private)

- (IBAction) changeFont: (id) sender
{
  [preferencesController changeFont];
}

- (void) colorPanelColorDidChange: (NSNotification *) notification
{
  [preferencesController colorPanelColorDidChange];
}

- (IBAction) openConnection: (id) sender
{
  MUConnectionWindowController *controller;
  MUProfile *profile = [sender representedObject];
  controller = [[MUConnectionWindowController alloc] initWithProfile: profile];
  
  [self openConnectionWithController: controller];
  
  [controller release];
}

- (void) openConnectionWithController: (MUConnectionWindowController *) controller
{
  [controller setDelegate: self];
  
  [connectionWindowControllers addObject: controller];
  [controller showWindow: self];
  [controller connect: nil];
}

- (void) playNotificationSound
{
  [[NSSound soundNamed: [[NSUserDefaults standardUserDefaults] stringForKey: MUPSoundChoice]] play];
}

- (void) rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect
{
  MUWorldRegistry *registry = [MUServices worldRegistry];
  MUProfileRegistry *profiles = [MUServices profileRegistry];
  unsigned worldsCount = [registry count];
  unsigned menuCount = [openConnectionMenu numberOfItems];
  
  for (int menuItemIndex = menuCount - 1; menuItemIndex >= 0; menuItemIndex--)
  {
    [openConnectionMenu removeItemAtIndex: menuItemIndex];
  }
  
  for (unsigned i = 0; i < worldsCount; i++)
  {
    MUWorld *world = [registry worldAtIndex: i];
    MUProfile *profile = [profiles profileForWorld: world];
    NSArray *players = [world players];
    NSMenuItem *worldItem = [[NSMenuItem alloc] init];
    NSMenu *worldMenu = [[NSMenu alloc] initWithTitle: [world name]];
    NSMenuItem *connectItem = [[NSMenuItem alloc] initWithTitle: _(MULConnectWithoutLogin)
                                                         action: @selector (openConnection:)
                                                  keyEquivalent: @""];
    unsigned playersCount = [players count];
    
    [connectItem setTarget: self];
    [connectItem setRepresentedObject: profile];
    
    if (autoconnect)
    {
      [profile setWorld: world];
      if ([profile autoconnect])
        [self openConnection: connectItem];
    }
    
    for (unsigned j = 0; j < playersCount; j++)
    {
      MUPlayer *player = [players objectAtIndex: j];
      profile = [profiles profileForWorld: world player: player];
      
      NSMenuItem *playerItem = [[NSMenuItem alloc] initWithTitle: [player name]
                                                          action: @selector (openConnection:)
                                                   keyEquivalent: @""];
      [playerItem setTarget: self];
      [playerItem setRepresentedObject: profile];
      
      if (autoconnect)
      {
        [profile setWorld: world];
        [profile setPlayer: player];
        if ([profile autoconnect])
          [self openConnection: playerItem];
      }
      
      [worldMenu addItem: playerItem];
      [playerItem release];
    }
    
    if (playersCount > 0)
    {
      [worldMenu addItem: [NSMenuItem separatorItem]];
    }
    
    [worldMenu addItem: connectItem];
    [worldItem setTitle: [world name]];
    [worldItem setSubmenu: worldMenu];
    [openConnectionMenu addItem: worldItem];
    [worldItem release];
    [worldMenu release];
    [connectItem release];
  }
}

- (void) recursivelyConfirmClose: (BOOL) cont
{
  if (cont)
  {
    unsigned count = [connectionWindowControllers count];
    
    while (count--)
    {
      MUConnectionWindowController *controller = [connectionWindowControllers objectAtIndex: count];
      if (controller && [controller isConnected])
      {
        [controller confirmClose: @selector (recursivelyConfirmClose:)];
        return;
      }
    }
  }
  
  [NSApp replyToApplicationShouldTerminate: cont];
}

- (BOOL) shouldPlayNotificationSound
{
  return ([[NSUserDefaults standardUserDefaults] boolForKey: MUPPlaySounds]
          && (![NSApp isActive] || [[NSUserDefaults standardUserDefaults] boolForKey: MUPPlayWhenActive]));
}

- (void) updateApplicationBadge
{
  NSDictionary *attributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSColor whiteColor], NSForegroundColorAttributeName,
    [NSFont fontWithName: @"Helvetica Bold" size: 25.0], NSFontAttributeName,
    nil];
  NSAttributedString *unreadCountString =
    [NSAttributedString attributedStringWithString: [NSString stringWithFormat: @"%@", [NSNumber numberWithUnsignedInt: unreadCount]]
                                        attributes: attributeDictionary];
  NSImage *appImage, *newAppImage, *badgeImage;
  NSSize newAppImageSize, badgeImageSize;
  NSPoint unreadCountStringLocationPoint;
  
  appImage = [NSImage imageNamed: @"NSApplicationIcon"];
  
  newAppImage = [[NSImage alloc] initWithSize: [appImage size]];
  newAppImageSize = [newAppImage size];
  
  [newAppImage lockFocus];
  
  [appImage drawInRect: NSMakeRect (0, 0, newAppImageSize.width, newAppImageSize.height)
              fromRect: NSMakeRect (0, 0, [appImage size].width, [appImage size].height)
             operation: NSCompositeCopy
              fraction: 1.0];
  
  if (unreadCount > 0)
  {
    if (unreadCount < 100)
      badgeImage = [NSImage imageNamed: @"badge-1-2"];
    else if (unreadCount < 1000)
      badgeImage = [NSImage imageNamed: @"badge-3"];
    else if (unreadCount < 10000)
      badgeImage = [NSImage imageNamed: @"badge-4"];
    else
      badgeImage = [NSImage imageNamed: @"badge-5"];
    
    
    badgeImageSize = [badgeImage size];
    
    [badgeImage drawInRect: NSMakeRect (newAppImageSize.width - badgeImageSize.width,
                                       newAppImageSize.height - badgeImageSize.height,
                                       badgeImageSize.width,
                                       badgeImageSize.height)
                  fromRect: NSMakeRect (0, 0, badgeImageSize.width, badgeImageSize.height)
                 operation: NSCompositeSourceOver
                  fraction: 1.0];
    
    if (unreadCount < 10)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 19.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else if (unreadCount < 100)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 12.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else if (unreadCount < 1000)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 14.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else if (unreadCount < 10000)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 12.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 10.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    
    
    [unreadCountString drawAtPoint: unreadCountStringLocationPoint];
  }
  
  [newAppImage unlockFocus];
  
  [NSApp setApplicationIconImage: newAppImage];
  [newAppImage release];
}

- (void) worldsDidChange: (NSNotification *) notification
{
  [self rebuildConnectionsMenuWithAutoconnect: NO];
}

@end
