//
// MUSoundsPreferencesViewController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUSoundsPreferencesViewController.h"

@interface MUSoundsPreferencesViewController ()
{
  BOOL _isUsingUserSelectedSound;
  NSMenuItem *_selectedMenuItem;
}

- (void) _chooseSound: (id) sender;
- (void) _playSoundAtURL: (NSURL *) soundURL;
- (void) _populateSoundsPopUpMenu;
- (void) _selectSoundFromMenu: (id) sender;

@end

#pragma mark -

@implementation MUSoundsPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (id) init
{
  if (!(self = [super initWithNibName: @"MUSoundsPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"sounds";
  _toolbarItemImage = [NSImage imageNamed: @"Sounds"];
  _toolbarItemLabel = _(MULPreferencesSounds);
  
  _isUsingUserSelectedSound = NO;
  _selectedMenuItem = nil;
  
  return self;
}

- (void) awakeFromNib
{
  [self _populateSoundsPopUpMenu];
}

#pragma mark - Actions

- (void) playCurrentSound:(id)sender
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [self _playSoundAtURL: [NSURL URLWithString: [userDefaults objectForKey: MUPSoundChoice]]];
}

#pragma mark - Private methods

- (void) _chooseSound: (id) sender
{
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  
  openPanel.allowedFileTypes = [NSSound soundUnfilteredTypes];
  openPanel.allowsMultipleSelection = NO;
  openPanel.canChooseDirectories = NO;
  openPanel.canChooseFiles = YES;
  openPanel.directoryURL = [[NSURL alloc] initFileURLWithPath: NSHomeDirectory ()];
  
  if ([openPanel runModal] == NSOKButton)
  {
    NSURL *selectedURL = openPanel.URLs[0]; // Guaranteed to be only one since we disallowed multiples.
    
    [[NSUserDefaults standardUserDefaults] setObject: selectedURL.absoluteString forKey: MUPSoundChoice];
    
    if (_isUsingUserSelectedSound)
    {
      _selectedMenuItem.title = [selectedURL.path.lastPathComponent stringByDeletingPathExtension];
      _selectedMenuItem.representedObject = selectedURL;
      
      [soundsPopUpButton selectItem: _selectedMenuItem];
    }
    else
    {
      NSMenuItem *currentSelectionMenuItem = [[NSMenuItem alloc] init];
      
      currentSelectionMenuItem.title = [selectedURL.path.lastPathComponent stringByDeletingPathExtension];
      currentSelectionMenuItem.representedObject = selectedURL;
      currentSelectionMenuItem.image = [NSImage imageNamed: @"MusicNote"];
      
      [soundsPopUpButton.menu insertItem: currentSelectionMenuItem atIndex: 0];
      [soundsPopUpButton.menu insertItem: [NSMenuItem separatorItem] atIndex: 1];
      
      [soundsPopUpButton selectItem: currentSelectionMenuItem];
      _selectedMenuItem = currentSelectionMenuItem;
      
      _isUsingUserSelectedSound = YES;
    }
  }
  else
  {
    [soundsPopUpButton selectItem: _selectedMenuItem];
  }
}

- (void) _playSoundAtURL: (NSURL *) soundURL
{
  NSSound *sound = [[NSSound alloc] initWithContentsOfURL: soundURL byReference: YES];
  
  sound.volume = [[NSUserDefaults standardUserDefaults] floatForKey: MUPSoundVolume];
  
  [sound performSelectorOnMainThread: @selector (play) withObject: nil waitUntilDone: NO];
}

- (void) _populateSoundsPopUpMenu
{
  NSMutableArray *systemSoundURLs = [NSMutableArray array];
  
  for (NSString *libraryPath in NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSAllDomainsMask, YES))
  {
    NSString *soundsDirectoryPath = [libraryPath stringByAppendingPathComponent: @"Sounds"];
    
    for (NSString *fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: soundsDirectoryPath
                                                                                   error: NULL])
    {
      NSURL *fileURL = [NSURL fileURLWithPath: [soundsDirectoryPath stringByAppendingPathComponent: fileName]];
      [systemSoundURLs addObject: fileURL];
    }
  }
  
  NSURL *currentSoundURL = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: MUPSoundChoice]];
  NSMenu *newMenu = [[NSMenu alloc] init];
  NSMenuItem *itemToSelect = nil;
  
  if ([systemSoundURLs containsObject: currentSoundURL])
    _isUsingUserSelectedSound = NO;
  else
  {
    _isUsingUserSelectedSound = YES;
    
    NSMenuItem *currentSelectionMenuItem = [[NSMenuItem alloc] init];
    
    currentSelectionMenuItem.title = [currentSoundURL.path.lastPathComponent stringByDeletingPathExtension];
    currentSelectionMenuItem.representedObject = currentSoundURL;
    currentSelectionMenuItem.image = [NSImage imageNamed: @"MusicNote"];
    currentSelectionMenuItem.image.size = NSMakeSize (16.0, 16.0);
    
    [newMenu addItem: currentSelectionMenuItem];
    [newMenu addItem: [NSMenuItem separatorItem]];
    itemToSelect = currentSelectionMenuItem;
  }
  
  for (NSURL *systemSoundURL in systemSoundURLs)
  {
    NSMenuItem *systemSoundMenuItem = [[NSMenuItem alloc] init];
    
    systemSoundMenuItem.title = [systemSoundURL.path.lastPathComponent stringByDeletingPathExtension];
    systemSoundMenuItem.representedObject = systemSoundURL;
    systemSoundMenuItem.target = self;
    systemSoundMenuItem.action = @selector (_selectSoundFromMenu:);
    systemSoundMenuItem.image = [NSImage imageNamed: @"MusicNote"];
    systemSoundMenuItem.image.size = NSMakeSize (16.0, 16.0);
    
    [newMenu addItem: systemSoundMenuItem];
    if ([currentSoundURL isEqual: systemSoundURL])
      itemToSelect = systemSoundMenuItem;
  }
  
  [newMenu addItem: [NSMenuItem separatorItem]];
  
  NSMenuItem *chooseAnotherSoundMenuItem = [[NSMenuItem alloc] init];
  
  chooseAnotherSoundMenuItem.title = _(MULPreferencesChooseAnotherSound);
  chooseAnotherSoundMenuItem.representedObject = nil;
  chooseAnotherSoundMenuItem.target = self;
  chooseAnotherSoundMenuItem.action = @selector (_chooseSound:);
  
  [newMenu addItem: chooseAnotherSoundMenuItem];
  
  soundsPopUpButton.menu = newMenu;
  
  if (itemToSelect)
  {
    [soundsPopUpButton selectItem: itemToSelect];
    _selectedMenuItem = itemToSelect;
  }
}

- (void) _selectSoundFromMenu: (id) sender
{
  NSMenuItem *menuItem = (NSMenuItem *) sender;
  NSURL *representedURL = menuItem.representedObject;
  
  [self _playSoundAtURL: representedURL];
  
  [[NSUserDefaults standardUserDefaults] setObject: representedURL.absoluteString forKey: MUPSoundChoice];
  _selectedMenuItem = soundsPopUpButton.selectedItem;
  
  if (_isUsingUserSelectedSound) // Remove the top user-selected sound menu item if it exists.
  {
    [soundsPopUpButton.menu removeItemAtIndex: 1];
    [soundsPopUpButton.menu removeItemAtIndex: 0];
    
    _isUsingUserSelectedSound = NO;
  }
}

@end
