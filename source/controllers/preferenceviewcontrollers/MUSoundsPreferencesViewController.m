//
// MUSoundsPreferencesViewController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUSoundsPreferencesViewController.h"

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
  
  NSMutableArray *foundPaths = [NSMutableArray array];
  
  for (NSString *libraryPath in NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSAllDomainsMask, YES))
  {
    NSString *searchPath = [libraryPath stringByAppendingPathComponent: @"Sounds"];
  	
  	for (NSString *filePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: searchPath error: NULL])
      [foundPaths addObject: filePath.stringByDeletingPathExtension];
  }
  
  _sounds = [foundPaths copy];
  
  return self;
}

- (IBAction) chooseSound: (id) sender
{
  ;
}

@end
