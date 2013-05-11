//
// MULoggingPreferencesViewController.m
//
// Copyright (c) 2013 3James Software. All rights reserved.
//

#import "MULoggingPreferencesViewController.h"

@interface MULoggingPreferencesViewController ()
{
  BOOL _isUsingUserSelectedDirectory;
  NSMenuItem *_selectedMenuItem;
}

- (void) _chooseLoggingLocation: (id) sender;
- (void) _populateLoggingLocationsPopUpMenu;
- (void) _selectLoggingLocationFromMenu: (id) sender;

@end

#pragma mark -

@implementation MULoggingPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (id) init
{
  if (!(self = [super initWithNibName: @"MULoggingPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"logging";
  _toolbarItemImage = nil;
  _toolbarItemLabel = _(MULPreferencesLogging);
  
  _selectedMenuItem = nil;
  
  return self;
}

- (void) awakeFromNib
{
  [self _populateLoggingLocationsPopUpMenu];
}

#pragma mark - Private methods

- (void) _chooseLoggingLocation: (id) sender
{
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseDirectories = YES;
  openPanel.canChooseFiles = NO;
  openPanel.directoryURL = [[NSURL alloc] initFileURLWithPath: NSHomeDirectory ()];
  
  if ([openPanel runModal] == NSOKButton)
  {
    NSURL *selectedURL = openPanel.URLs[0]; // Guaranteed to be only one since we disallowed multiples.
    
    //[[NSUserDefaults standardUserDefaults] setObject: selectedURL.absoluteString forKey: MUPLoggingDirectory];
    
    if (_isUsingUserSelectedDirectory)
    {
      _selectedMenuItem.title = [selectedURL.path stringByAbbreviatingWithTildeInPath];
      _selectedMenuItem.representedObject = selectedURL;
      _selectedMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: selectedURL.path];
      _selectedMenuItem.image.size = NSMakeSize (16.0, 16.0);
      
      [loggingLocationsPopUpButton selectItem: _selectedMenuItem];
    }
    else
    {
      NSMenuItem *currentSelectionMenuItem = [[NSMenuItem alloc] init];
      
      currentSelectionMenuItem.title = [selectedURL.path stringByAbbreviatingWithTildeInPath];
      currentSelectionMenuItem.representedObject = selectedURL;
      currentSelectionMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: selectedURL.path];
      currentSelectionMenuItem.image.size = NSMakeSize (16.0, 16.0);
      
      [loggingLocationsPopUpButton.menu insertItem: currentSelectionMenuItem atIndex: 0];
      [loggingLocationsPopUpButton.menu insertItem: [NSMenuItem separatorItem] atIndex: 1];
      
      [loggingLocationsPopUpButton selectItem: currentSelectionMenuItem];
      _selectedMenuItem = currentSelectionMenuItem;
      
      _isUsingUserSelectedDirectory = YES;
    }
  }
  else
  {
    [loggingLocationsPopUpButton selectItem: _selectedMenuItem];
  }
}

- (void) _populateLoggingLocationsPopUpMenu
{
  NSMenu *newMenu = [[NSMenu alloc] init];
  NSMenuItem *itemToSelect = nil;
  
#if 0
  NSMenuItem *icloudMenuItem = [[NSMenuItem alloc] init];
  
  icloudMenuItem.title = @"iCloud";
  icloudMenuItem.representedObject = @"iCloud";
  icloudMenuItem.image = [NSImage imageNamed: @"iCloud"];
  icloudMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  [newMenu addItem: icloudMenuItem];
  [newMenu addItem: [NSMenuItem separatorItem]];
#endif
  
  NSMenuItem *documentsMenuItem = [[NSMenuItem alloc] init];
  NSString *documentsPath = @"~/Documents/Koan Logs/";
  
  documentsMenuItem.title = @"~/Documents/Koan Logs";
  documentsMenuItem.representedObject = [NSURL fileURLWithPath: [documentsPath stringByExpandingTildeInPath]];
  documentsMenuItem.target = self;
  documentsMenuItem.action = @selector (_selectLoggingLocationFromMenu:);
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: [documentsPath stringByExpandingTildeInPath]])
    documentsMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: [documentsPath stringByExpandingTildeInPath]];
  else
    documentsMenuItem.image = [NSImage imageNamed: @"NSFolder"];
  
  documentsMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  [newMenu addItem: documentsMenuItem];
  
  NSMenuItem *libraryMenuItem = [[NSMenuItem alloc] init];
  NSString *libraryPath = @"~/Library/Logs/Koan";
  
  libraryMenuItem.title = libraryPath;
  libraryMenuItem.representedObject = [NSURL fileURLWithPath: [libraryPath stringByExpandingTildeInPath]];
  libraryMenuItem.target = self;
  libraryMenuItem.action = @selector (_selectLoggingLocationFromMenu:);
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: [libraryPath stringByExpandingTildeInPath]])
    libraryMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: [libraryPath stringByExpandingTildeInPath]];
  else
    libraryMenuItem.image = [NSImage imageNamed: @"NSFolder"];
  
  libraryMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  [newMenu addItem: libraryMenuItem];
  [newMenu addItem: [NSMenuItem separatorItem]];
  
  NSMenuItem *chooseAnotherLocationMenuItem = [[NSMenuItem alloc] init];
  
  chooseAnotherLocationMenuItem.title = _(MULPreferencesChooseAnotherLocation);
  chooseAnotherLocationMenuItem.representedObject = nil;
  chooseAnotherLocationMenuItem.target = self;
  chooseAnotherLocationMenuItem.action = @selector (_chooseLoggingLocation:);
  
  [newMenu addItem: chooseAnotherLocationMenuItem];
  
  loggingLocationsPopUpButton.menu = newMenu;
  
  if (itemToSelect)
  {
    [loggingLocationsPopUpButton selectItem: itemToSelect];
    _selectedMenuItem = itemToSelect;
  }
}

- (void) _selectLoggingLocationFromMenu: (id) sender
{
  NSMenuItem *menuItem = (NSMenuItem *) sender;
  NSURL *representedURL = menuItem.representedObject;
  
  //[[NSUserDefaults standardUserDefaults] setObject: representedURL.absoluteString forKey: MUPSoundChoice];
  _selectedMenuItem = loggingLocationsPopUpButton.selectedItem;
  
  if (_isUsingUserSelectedDirectory) // Remove the top user-selected logging location menu item if it exists.
  {
    [loggingLocationsPopUpButton.menu removeItemAtIndex: 1];
    [loggingLocationsPopUpButton.menu removeItemAtIndex: 0];
    
    _isUsingUserSelectedDirectory = NO;
  }
}

@end
