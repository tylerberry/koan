//
// MUProfilesWindowController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUPreferencesController.h"

@interface MUPreferencesController ()

- (void) postGlobalBackgroundColorDidChangeNotification;
- (void) postGlobalFontDidChangeNotification;
- (void) postGlobalLinkColorDidChangeNotification;
- (void) postGlobalTextColorDidChangeNotification;
- (void) postGlobalVisitedLinkColorDidChangeNotification;
- (NSArray *) systemSoundsArray;

@end

#pragma mark -

@implementation MUPreferencesController

- (void) awakeFromNib
{
  [self systemSoundsArray];
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
  
  [self postGlobalFontDidChangeNotification];
}

- (void) colorPanelColorDidChange
{
  if (globalTextColorWell.isActive)
  	[self postGlobalTextColorDidChangeNotification];
  else if (globalBackgroundColorWell.isActive)
  	[self postGlobalBackgroundColorDidChangeNotification];
  else if (globalLinkColorWell.isActive)
  	[self postGlobalLinkColorDidChangeNotification];
  else if (globalVisitedLinkColorWell.isActive)
  	[self postGlobalVisitedLinkColorDidChangeNotification];
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

- (void) postGlobalBackgroundColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalBackgroundColorDidChangeNotification
  																										object: self];
}

- (void) postGlobalFontDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalFontDidChangeNotification
  																										object: self];
}

- (void) postGlobalLinkColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalLinkColorDidChangeNotification
  																										object: self];
}

- (void) postGlobalTextColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalTextColorDidChangeNotification
  																										object: self];
}

- (void) postGlobalVisitedLinkColorDidChangeNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUGlobalVisitedLinkColorDidChangeNotification
  																										object: self];
}

- (NSArray *) systemSoundsArray
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
