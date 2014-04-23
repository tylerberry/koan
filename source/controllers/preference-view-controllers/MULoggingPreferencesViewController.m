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
- (void) _moveLogsFromOldLocation: (NSURL *) oldURL toNewLocation: (NSURL *) newURL;
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
  openPanel.canCreateDirectories = YES;
  openPanel.directoryURL = [[NSURL alloc] initFileURLWithPath: NSHomeDirectory ()];
  
  if ([openPanel runModal] == NSOKButton)
  {
    NSURL *selectedURL = openPanel.URLs[0]; // Guaranteed to be only one since we disallowed multiples.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *oldURL = [NSURL URLWithString: [defaults objectForKey: MUPLogDirectoryURL]];
    
    if ([oldURL isEqual: selectedURL])
      return;
    
    [defaults setObject: selectedURL.absoluteString forKey: MUPLogDirectoryURL];
    
    [self _moveLogsFromOldLocation: oldURL toNewLocation: selectedURL];
    
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

- (void) _moveLogsFromOldLocation: (NSURL *) oldURL toNewLocation: (NSURL *) newURL
{
  NSError *error;
  NSFileManager *manager = [NSFileManager defaultManager];
  BOOL newURLIsDirectory;
  
  if (![manager fileExistsAtPath: newURL.path isDirectory: &newURLIsDirectory])
  {
    [manager createDirectoryAtURL: newURL
      withIntermediateDirectories: YES
                       attributes: nil
                            error: &error];
  }
  else if (!newURLIsDirectory)
  {
    NSLog (@"Warning: New log URL %@ exists but is not a directory. This should generally not happen.", newURL);
    return;
  }
  
  NSArray *contents = [manager contentsOfDirectoryAtURL: oldURL
                             includingPropertiesForKeys: nil
                                                options: 0
                                                  error: &error];
  
  for (NSURL *item in contents)
    [manager moveItemAtURL: item toURL: [newURL URLByAppendingPathComponent: [item lastPathComponent]] error: &error];
  
  [manager removeItemAtURL: oldURL error: &error];
}

- (void) _populateLoggingLocationsPopUpMenu
{
  NSMenu *newMenu = [[NSMenu alloc] init];
  NSMenuItem *itemToSelect = nil;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSURL *currentDirectoryURL = [NSURL URLWithString: [defaults stringForKey: MUPLogDirectoryURL]];
  
  NSString *documentsPath = @"~/Documents/Koan Logs";
  NSURL *documentsURL = [NSURL fileURLWithPath: [documentsPath stringByExpandingTildeInPath]];
  
  NSString *libraryPath = @"~/Library/Logs/Koan";
  NSURL *libraryURL = [NSURL fileURLWithPath: [libraryPath stringByExpandingTildeInPath]];
  
  if (![currentDirectoryURL isEqual: documentsURL]
      && ![currentDirectoryURL isEqual: libraryURL])
  {
    _isUsingUserSelectedDirectory = YES;
    
    NSMenuItem *currentSelectionMenuItem = [[NSMenuItem alloc] init];
    
    currentSelectionMenuItem.title = [currentDirectoryURL.path stringByAbbreviatingWithTildeInPath];
    currentSelectionMenuItem.representedObject = currentDirectoryURL;
    currentSelectionMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: currentDirectoryURL.path];
    currentSelectionMenuItem.image.size = NSMakeSize (16.0, 16.0);
    
    [newMenu addItem: currentSelectionMenuItem];
    [newMenu addItem: [NSMenuItem separatorItem]];
    itemToSelect = currentSelectionMenuItem;
  }
  
#if 0
  NSMenuItem *icloudMenuItem = [[NSMenuItem alloc] init];
  NSURL *icloudURL = [NSURL URLFromString: @"https://www.icloud.com/"];
  
  icloudMenuItem.title = @"iCloud";
  icloudMenuItem.representedObject = icloudURL;
  icloudMenuItem.image = [NSImage imageNamed: @"iCloud"];
  icloudMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  [newMenu addItem: icloudMenuItem];
  
  if ([currentDirectoryURL isEqual: icloudURL])
    itemToSelect = icloudMenuItem;
  
  [newMenu addItem: [NSMenuItem separatorItem]];
#endif
  
  NSMenuItem *documentsMenuItem = [[NSMenuItem alloc] init];
  
  documentsMenuItem.title = documentsPath;
  documentsMenuItem.representedObject = documentsURL;
  documentsMenuItem.target = self;
  documentsMenuItem.action = @selector (_selectLoggingLocationFromMenu:);
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: [documentsPath stringByExpandingTildeInPath]])
    documentsMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: [documentsPath stringByExpandingTildeInPath]];
  else
    documentsMenuItem.image = [NSImage imageNamed: @"NSFolder"];
  
  documentsMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  [newMenu addItem: documentsMenuItem];
  
  if ([currentDirectoryURL isEqual: documentsURL])
    itemToSelect = documentsMenuItem;
  
  NSMenuItem *libraryMenuItem = [[NSMenuItem alloc] init];
  
  libraryMenuItem.title = libraryPath;
  libraryMenuItem.representedObject = libraryURL;
  libraryMenuItem.target = self;
  libraryMenuItem.action = @selector (_selectLoggingLocationFromMenu:);
  
  if ([[NSFileManager defaultManager] fileExistsAtPath: [libraryPath stringByExpandingTildeInPath]])
    libraryMenuItem.image = [[NSWorkspace sharedWorkspace] iconForFile: [libraryPath stringByExpandingTildeInPath]];
  else
    libraryMenuItem.image = [NSImage imageNamed: @"NSFolder"];
  
  libraryMenuItem.image.size = NSMakeSize (16.0, 16.0);
  
  [newMenu addItem: libraryMenuItem];
  
  if ([currentDirectoryURL isEqual: libraryURL])
    itemToSelect = libraryMenuItem;
  
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
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSURL *oldURL = [NSURL URLWithString: [defaults objectForKey: MUPLogDirectoryURL]];
  
  if ([oldURL isEqual: representedURL])
    return;
  
  [defaults setObject: representedURL.absoluteString forKey: MUPLogDirectoryURL];
  
  [self _moveLogsFromOldLocation: oldURL toNewLocation: representedURL];
  
  _selectedMenuItem = loggingLocationsPopUpButton.selectedItem;
  
  if (_isUsingUserSelectedDirectory) // Remove the top user-selected logging location menu item if it exists.
  {
    [loggingLocationsPopUpButton.menu removeItemAtIndex: 1];
    [loggingLocationsPopUpButton.menu removeItemAtIndex: 0];
    
    _isUsingUserSelectedDirectory = NO;
  }
}

@end
