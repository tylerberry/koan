//
// MUProfilesWindowController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUPreferencesController.h"

@interface MUPreferencesController ()

- (void) _postGlobalBackgroundColorDidChangeNotification;
- (void) _postGlobalFontDidChangeNotification;
- (void) _postGlobalLinkColorDidChangeNotification;
- (void) _postGlobalTextColorDidChangeNotification;
- (void) _postGlobalVisitedLinkColorDidChangeNotification;
- (NSArray *) _systemSoundsArray;

@end

#pragma mark -

@implementation MUPreferencesController

- (void) awakeFromNib
{
  [self _systemSoundsArray];
}

- (IBAction) changeFont: (id) sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = fontManager.selectedFont;
  
  if (selectedFont == nil)
    selectedFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  NSFont *panelFont = [fontManager convertFont: selectedFont];
  
  id currentPrefsValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
  [currentPrefsValues setValue: panelFont.fontName forKey: MUPFontName];
  [currentPrefsValues setValue: @(panelFont.pointSize) forKey: MUPFontSize];
  
  [self _postGlobalFontDidChangeNotification];
}

- (void) colorPanelColorDidChange
{
  if (globalTextColorWell.isActive)
  	[self _postGlobalTextColorDidChangeNotification];
  else if (globalBackgroundColorWell.isActive)
  	[self _postGlobalBackgroundColorDidChangeNotification];
  else if (globalLinkColorWell.isActive)
  	[self _postGlobalLinkColorDidChangeNotification];
  else if (globalVisitedLinkColorWell.isActive)
  	[self _postGlobalVisitedLinkColorDidChangeNotification];
}

- (void) playSelectedSound: (id) sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSSound *sound = [NSSound soundNamed: [defaults stringForKey: MUPSoundChoice]];
  [sound play];
}

- (void) showPreferencesWindow: (id) sender
{
  [preferencesWindow makeKeyAndOrderFront: self];
}

#pragma mark - Private methods

- (void) _postGlobalBackgroundColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalBackgroundColorDidChangeNotification
  																										object: self];
}

- (void) _postGlobalFontDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalFontDidChangeNotification
  																										object: self];
}

- (void) _postGlobalLinkColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalLinkColorDidChangeNotification
  																										object: self];
}

- (void) _postGlobalTextColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalTextColorDidChangeNotification
  																										object: self];
}

- (void) _postGlobalVisitedLinkColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalVisitedLinkColorDidChangeNotification
  																										object: self];
}

- (NSArray *) _systemSoundsArray
{
  NSMutableArray *foundPaths = [NSMutableArray array];
  
  for (NSString *libraryPath in NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSAllDomainsMask, YES))
  {
    NSString *searchPath = [libraryPath stringByAppendingPathComponent: @"Sounds"];
  	
  	for (NSString *filePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: searchPath error: NULL])
  	{
      [foundPaths addObject: filePath.stringByDeletingPathExtension];
  	}
  }
  
  return foundPaths;
}

@end
