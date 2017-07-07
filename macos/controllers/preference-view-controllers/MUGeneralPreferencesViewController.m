//
// MUGeneralPreferencesViewController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUGeneralPreferencesViewController.h"

@interface MUGeneralPreferencesViewController ()

- (void) _populateTelnetHandlerPopUpMenu;

@end

#pragma mark -

@implementation MUGeneralPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (instancetype) init
{
  if (!(self = [super initWithNibName: @"MUGeneralPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"general";
  _toolbarItemImage = [NSImage imageNamed: NSImageNamePreferencesGeneral];
  _toolbarItemLabel = _(MULPreferencesGeneral);
  
  return self;
}

- (void) awakeFromNib
{
  [self _populateTelnetHandlerPopUpMenu];
}

#pragma mark - Actions

- (IBAction) chooseTelnetHandler: (id) sender
{
  NSMenuItem *senderMenuItem = (NSMenuItem *) sender;
  
  OSStatus status = LSSetDefaultHandlerForURLScheme (CFSTR ("telnet"),
                                                     (__bridge CFStringRef) senderMenuItem.representedObject);
  
  if (status != noErr)
  {
    // FIXME: Do something. Or something.
  }
}

#pragma mark - Private methods

- (void) _populateTelnetHandlerPopUpMenu
{
  NSMenu *newMenu = [[NSMenu alloc] init];
  NSMenuItem *menuItemToSelect = nil;
  NSString *identifierForCurrentHandler = (__bridge_transfer NSString *) LSCopyDefaultHandlerForURLScheme (CFSTR ("telnet"));
  
  NSMenuItem *koanMenuItem = [[NSMenuItem alloc] init];
  NSBundle *koanBundle = [NSBundle mainBundle];
  NSString *koanBundleName = [koanBundle objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
  NSString *koanBundleVersion = [koanBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
  
  koanMenuItem.title = [NSString stringWithFormat: @"%@ (%@)", koanBundleName, koanBundleVersion];
  
  NSString *koanBundleIconPath = [koanBundle pathForImageResource: [koanBundle objectForInfoDictionaryKey: @"CFBundleIconFile"]];
  
  koanMenuItem.image = [[NSImage alloc] initWithContentsOfFile: koanBundleIconPath];
  koanMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  koanMenuItem.target = self;
  koanMenuItem.action = @selector (chooseTelnetHandler:);
  koanMenuItem.representedObject = koanBundle.bundleIdentifier;
  
  if ([koanBundle.bundleIdentifier isEqualToString: identifierForCurrentHandler])
    menuItemToSelect = koanMenuItem;
  
  [newMenu addItem: koanMenuItem];
  [newMenu addItem: [NSMenuItem separatorItem]];
  
  NSArray *telnetHandlerIdentifiers = (__bridge_transfer NSArray *) LSCopyAllHandlersForURLScheme (CFSTR ("telnet"));
  
  for (NSString *identifier in telnetHandlerIdentifiers)
  {
    NSString *bundlePath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier: identifier];
    NSBundle *bundle = [NSBundle bundleWithPath: bundlePath];
    
    if (bundle) // Launch Services sometimes keeps track of bundles that used to exist, but don't anymore.
    {
      if ([bundle.bundleIdentifier isEqualToString: koanBundle.bundleIdentifier])
        continue;
      
      NSMenuItem *item = [[NSMenuItem alloc] init];
      
      NSString *bundleName = [bundle objectForInfoDictionaryKey: @"CFBundleDisplayName"];
      if (!bundleName)
        bundleName = [bundle objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
      if (!bundleName)
        bundleName = [bundle objectForInfoDictionaryKey: (NSString *) kCFBundleExecutableKey];
      
      NSString *bundleVersion = [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
      if (!bundleVersion)
        bundleVersion = [bundle objectForInfoDictionaryKey: (NSString *) kCFBundleVersionKey];
    
      item.title = [NSString stringWithFormat: @"%@ (%@)", bundleName, bundleVersion];
      
      NSString *bundleIconPath = [bundle pathForImageResource: [bundle objectForInfoDictionaryKey: @"CFBundleIconFile"]];
      
      item.image = [[NSImage alloc] initWithContentsOfFile: bundleIconPath];
      item.image.size = NSMakeSize (16.0, 16.0);
      
      item.target = self;
      item.action = @selector (chooseTelnetHandler:);
      item.representedObject = bundle.bundleIdentifier;
      
      if ([bundle.bundleIdentifier isEqualToString: identifierForCurrentHandler])
        menuItemToSelect = item;
      
      [newMenu addItem: item];
    }
  }
  
  telnetHandlerPopUpButton.menu = newMenu;
  
  if (menuItemToSelect)
    [telnetHandlerPopUpButton selectItem: menuItemToSelect];
}

@end
