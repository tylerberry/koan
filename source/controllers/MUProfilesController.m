//
// MUProfilesController.m
//
// Copyright (c) 2010 3James Software.
//

#import "MUProfilesController.h"
#import "J3PortFormatter.h"
#import "MUProfile.h"
#import "MUServices.h"

#import "ImageAndTextCell.h"

@interface MUProfilesController (Private)

#if 0
- (IBAction) changeFont: (id) sender;
- (void) colorPanelColorDidChange: (NSNotification *) notification;
- (void) globalBackgroundColorDidChange: (NSNotification *) notification;
- (void) globalFontDidChange: (NSNotification *) notification;
- (void) globalLinkColorDidChange: (NSNotification *) notification;
- (void) globalTextColorDidChange: (NSNotification *) notification;
- (void) globalVisitedLinkColorDidChange: (NSNotification *) notification;
#endif

- (void) registerForNotifications;

@end

#pragma mark -

@interface MUProfilesController (TreeController)

- (void) populateProfilesFromDefaults;
- (void) populateProfilesTree;

@end

#pragma mark -

@implementation MUProfilesController

@synthesize profilesTreeArray;

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUProfiles"]))
    return nil;
  
  profilesTreeArray = [[NSMutableArray alloc] init];
  
  return self;
}

- (void) awakeFromNib
{
  // J3PortFormatter *worldPortFormatter = [[[J3PortFormatter alloc] init] autorelease];
  
  // FIXME: [worldPortField setFormatter: worldPortFormatter];
  
  editingFont = nil;
  
  backgroundColorActive = NO;
  linkColorActive = NO;
  textColorActive = NO;
  visitedLinkColorActive = NO;
  
  [self performSelectorInBackground: @selector (populateProfilesTree)
                         withObject: nil];
  
  [self registerForNotifications];
}

- (void) dealloc
{
  [profilesTreeArray release];
  [super dealloc];
}

#pragma mark -
#pragma mark Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
  NSString *fontName = [values valueForKey: MUPFontName];
  int fontSize = [[values valueForKey: MUPFontSize] floatValue];
  NSFont *font = [NSFont fontWithName: fontName size: fontSize];
  
  if (font == nil)
  {
    font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  }
  
  [[NSFontManager sharedFontManager] setSelectedFont: font isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) goToWorldURL: (id) sender
{
  return;
}

#pragma mark -
#pragma mark NSOutlineView data source

- (id) outlineView: (NSOutlineView *) outlineView itemForPersistentObject: (id) object
{
  if (object && [object isKindOfClass: [NSString class]])
  {
  	return [[MUServices worldRegistry] worldForUniqueIdentifier: (NSString *) object];
  }
  
  return nil;
}

- (id) outlineView: (NSOutlineView *) outlineView persistentObjectForItem: (id) item
{
  id representedObject = [(NSTreeNode *) [(NSTreeNode *) item representedObject] representedObject];
  if ([representedObject isKindOfClass: [MUWorld class]])
  	return ((MUWorld *) representedObject).uniqueIdentifier;
  else
  	return nil;
}

#pragma mark -
#pragma mark NSOutlineView delegate

- (BOOL) outlineView: (NSOutlineView *) outlineView isGroupItem: (id) item
{
  return [outlineView parentForItem: item] == nil;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldCollapseItem: (id) item
{
  return [outlineView rowForItem: item] != 0;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldEditTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  return NO;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldSelectItem: (id) item
{
  return [self outlineView: outlineView isGroupItem: item] ? NO : YES;
}

- (void) outlineView: (NSOutlineView *) outlineView willDisplayCell: (id) cell forTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  if ([cell isKindOfClass: [ImageAndTextCell class]])
  {
    if ([self outlineView: outlineView isGroupItem: item])
      [cell setImage: nil];
    else
    {
      id representedObject = [(NSTreeNode *) [(NSTreeNode *) item representedObject] representedObject];
      
      if ([representedObject isKindOfClass: [MUWorld class]])
      {
        NSImage *worldImage = [[NSImage imageNamed: NSImageNameNetwork] retain];
        [worldImage setSize: NSMakeSize (16, 16)];
        [cell setImage: worldImage];
        [worldImage release];
      }
      else if ([representedObject isKindOfClass: [MUPlayer class]])
      {
        NSImage *playerImage = [[NSImage imageNamed: NSImageNameUser] retain];
        [playerImage setSize: NSMakeSize (16, 16)];
        [cell setImage: playerImage];
        [playerImage release];
      }
      else
      {
        NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode (kGenericFolderIcon)];
        [folderImage setSize: NSMakeSize (16, 16)];
        [cell setImage: folderImage];
      }
    }
  }
}

- (void) outlineView: (NSOutlineView *) outlineView willDisplayOutlineCell: (id) cell forTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  if ([outlineView rowForItem: item] == 0)
    [cell setTransparent: YES];
  else
    [cell setTransparent: NO];
}

- (void) outlineViewSelectionDidChange: (NSNotification *) notification
{
  return;
}

@end

#pragma mark -

@implementation MUProfilesController (Private)

#if 0

- (IBAction) changeFont: (id) sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = [fontManager selectedFont];
  NSFont *panelFont;
  
  if (selectedFont == nil)
  {
    selectedFont = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  }
  
  panelFont = [fontManager convertFont: selectedFont];
  
  [profileFontUseGlobalButton setState: NSOffState];
  [profileFontField setStringValue: [panelFont fullDisplayName]];
  editingFont = [panelFont copy];
}

- (void) colorPanelColorDidChange: (NSNotification *) notification
{
  if ([profileBackgroundColorWell isActive])
  {
    if (backgroundColorActive)
      [profileBackgroundColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = YES;
      linkColorActive = NO;
      textColorActive = NO;
      visitedLinkColorActive = NO;
    }
  }
  else if ([profileLinkColorWell isActive])
  {
    if (linkColorActive)
      [profileLinkColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = NO;
      linkColorActive = YES;
      textColorActive = NO;
      visitedLinkColorActive = NO;
    }
  }
  else if ([profileTextColorWell isActive])
  {
    if (textColorActive)
      [profileTextColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = NO;
      linkColorActive = NO;
      textColorActive = YES;
      visitedLinkColorActive = NO;
    }
  }
  else if ([profileVisitedLinkColorWell isActive])
  {
    if (visitedLinkColorActive)
      [profileVisitedLinkColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = NO;
      linkColorActive = NO;
      textColorActive = NO;
      visitedLinkColorActive = YES;
    }
  }
  else
  {
    backgroundColorActive = NO;
    linkColorActive = NO;
    textColorActive = NO;
    visitedLinkColorActive = NO;
  }
}

- (void) globalBackgroundColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileBackgroundColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPBackgroundColor];
    
    [profileBackgroundColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

- (void) globalFontDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileFontUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	NSString *fontName = [[defaults values] valueForKey: MUPFontName];
  	NSNumber *fontSize = [[defaults values] valueForKey: MUPFontSize];
    
    [editingFont release];
    editingFont = nil;
    
  	[profileFontField setStringValue: [[NSFont fontWithName: fontName size: [fontSize floatValue]] fullDisplayName]];
  }
}

- (void) globalLinkColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileBackgroundColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPLinkColor];
    
    [profileLinkColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

- (void) globalTextColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileTextColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPTextColor];
    
    [profileTextColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

- (void) globalVisitedLinkColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileBackgroundColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPVisitedLinkColor];
    
    [profileVisitedLinkColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

#endif

- (void) registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (colorPanelColorDidChange:)
                                               name: NSColorPanelColorDidChangeNotification
                                             object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalBackgroundColorDidChange:)
  																						 name: MUGlobalBackgroundColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalFontDidChange:)
  																						 name: MUGlobalFontDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalLinkColorDidChange:)
  																						 name: MUGlobalLinkColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalTextColorDidChange:)
  																						 name: MUGlobalTextColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalVisitedLinkColorDidChange:)
  																						 name: MUGlobalVisitedLinkColorDidChangeNotification
  																					 object: nil];
}

@end

#pragma mark -

@implementation MUProfilesController (TreeController)

- (void) populateProfilesFromDefaults
{
  MUWorldRegistry *worldRegistry = [MUWorldRegistry defaultRegistry];
  
  NSDictionary *localProfilesRootNodeDictionary = [NSDictionary dictionaryWithObject: @"PROFILES" forKey: @"name"];
  NSTreeNode *localProfilesNode = [NSTreeNode treeNodeWithRepresentedObject: localProfilesRootNodeDictionary];
  
  for (MUWorld *world in [worldRegistry worlds])
  {
    NSTreeNode *worldNode = [NSTreeNode treeNodeWithRepresentedObject: world];
    
    for (MUPlayer *player in [world children])
    {
      NSTreeNode *playerNode = [NSTreeNode treeNodeWithRepresentedObject: player];
      
      [[worldNode mutableChildNodes] addObject: playerNode];
    }
    
    [[localProfilesNode mutableChildNodes] addObject: worldNode];
  }
  
  NSDictionary *fakeFolder = [NSDictionary dictionaryWithObject: @"Folder" forKey: @"name"];
  [[localProfilesNode mutableChildNodes] addObject: [NSTreeNode treeNodeWithRepresentedObject: fakeFolder]];
  
  [self willChangeValueForKey: @"profilesTreeArray"];
  [profilesTreeArray addObject: localProfilesNode];
  [self didChangeValueForKey: @"profilesTreeArray"];
  
}

- (void) populateProfilesTree
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self populateProfilesFromDefaults];
  
  [profilesOutlineView setAutosaveExpandedItems: YES];
  [profilesOutlineView setAutosaveName: @"profilesOutlineView"];
  [profilesOutlineView reloadData];
  [profilesOutlineView expandItem: [profilesOutlineView itemAtRow: 0]];
	
	[pool release];
}

@end
