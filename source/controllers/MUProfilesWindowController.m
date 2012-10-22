//
// MUProfilesWindowController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUPlayerViewController.h"
#import "MUProfilesWindowController.h"
#import "MUPortFormatter.h"
#import "MUProfile.h"
#import "MUProfileContentView.h"
#import "MUProfileRegistry.h"
#import "MUProfileViewController.h"
#import "MUProfilesSection.h"
#import "MUSection.h"
#import "MUWorldViewController.h"

@interface MUProfilesWindowController ()
{
  NSMutableArray *profilesTreeArray;
  NSMutableArray *profilesExpandedItems;
  
  MUPlayerViewController *_playerViewController;
  MUProfileViewController *_profileViewController;
  MUWorldViewController *_worldViewController;
}

- (void) _applicationWillTerminate: (NSNotification *) notification;
- (void) _registerForNotifications;

@end

#pragma mark -

@interface MUProfilesWindowController (TreeController)

- (void) expandProfilesOutlineView;
- (void) populateProfilesFromWorldRegistry;
- (void) populateProfilesTree;
- (void) saveProfilesOutlineViewState;

@end

#pragma mark -

@implementation MUProfilesWindowController

@synthesize profilesTreeArray;

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUProfilesWindow"]))
    return nil;
  
  profilesTreeArray = [[NSMutableArray alloc] init];
  profilesExpandedItems = [[NSMutableArray alloc] init];
  
  _playerViewController = nil;
  _profileViewController = nil;
  _worldViewController = nil;
  
  [self populateProfilesTree];
  
  return self;
}

- (void) awakeFromNib
{
  [self _registerForNotifications];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
}

#pragma mark - Actions

- (IBAction) goToWorldURL: (id) sender
{
  return;
}

- (IBAction) showAddContextMenu: (id) sender
{
  NSPoint point = [NSEvent mouseLocation];
  NSPoint windowPoint = [self.window convertScreenToBase: point];
  NSLog (@"Location? x= %f, y = %f", (float) point.x, (float) point.y);
  NSLog (@"Location? x= %f, y = %f", (float) windowPoint.x, (float) windowPoint.y);
  
  NSEvent *event = [NSEvent mouseEventWithType: NSLeftMouseUp
                                      location: windowPoint
                                 modifierFlags: 0
                                     timestamp: NSTimeIntervalSince1970
                                  windowNumber: [self.window windowNumber]
                                       context: nil
                                   eventNumber: 0
                                    clickCount: 0
                                      pressure: 0.1];
  
  [NSMenu popUpContextMenu: addMenu withEvent: event forView: nil];
}

#pragma mark - Responder chain methods

- (IBAction) changeFont: (id) sender
{
  if (_profileViewController.profile.font == nil)
  {
    // If profile.font is nil, then we don't handle this message.
    [super changeFont: sender];
  }
  
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = fontManager.selectedFont;
  
  if (selectedFont == nil)
    selectedFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  NSFont *convertedFont = [fontManager convertFont: selectedFont];
  
  _profileViewController.profile.font = convertedFont;
}

#pragma mark - NSOutlineView data source

// I tried implementing this the recommended way, but in 10.6 at least there seems
// to be no functional way of getting it working.
//
// In particular, this doesn't seem to work:
//   <http://blog.pioneeringsoftware.co.uk/2008/09/10/outline-view-tree-controller-and-itemforpersistentobject>
//
// Therefore, I'm expanding the tree manually. I'm using the dataSource methods and
// calling them manually; the "saving" part works, but the "restoring" part doesn't.
// The outlineView:itemForPersistentObject: method *does* work, it's just evidently
// not getting called at the right times.

- (id) outlineView: (NSOutlineView *) outlineView itemForPersistentObject: (id) object
{
  if (object && [object isKindOfClass: [NSString class]])
  {
    // Iterate all the items. This is not straightforward because the outline
    // view items are nested. So you cannot just iterate the rows. Rows
    // correspond to root nodes only. The outline view interface does not
    // provide any means to query the hidden children within each collapsed row
    // either. However, the root nodes do respond to -childNodes. That makes it
    // possible to walk the tree.
    
    NSMutableArray *items = [NSMutableArray array];
    
    for (NSInteger i = 0; i < outlineView.numberOfRows; i++)
    {
      [items addObject: [outlineView itemAtRow: i]];
    }
    
    for (NSUInteger i = 0; i < items.count; i++)
    {
      NSTreeNode *shadowObject = items[i];
      MUTreeNode *node = shadowObject.representedObject;
      
      if ([node.uniqueIdentifier isEqualToString: object])
        return shadowObject;
      
      [items addObjectsFromArray: shadowObject.childNodes];
    }
  }
  
  return nil;
}

- (id) outlineView: (NSOutlineView *) outlineView persistentObjectForItem: (id) item
{
  NSTreeNode *node = (NSTreeNode *) item;
  
  if ([node.representedObject isKindOfClass: [MUWorld class]])
  	return ((MUWorld *) node.representedObject).uniqueIdentifier;
  else
  	return nil;
}

#pragma mark - NSOutlineView delegate

- (BOOL) outlineView: (NSOutlineView *) outlineView isGroupItem: (id) item
{
  NSTreeNode *node = (NSTreeNode *) item;
  
  return [node.representedObject isKindOfClass: [MUSection class]] ? YES : NO;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldCollapseItem: (id) item
{
  return [self outlineView: outlineView isGroupItem: item] ? NO : YES;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldEditTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  return NO;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldSelectItem: (id) item
{
  return [self outlineView: outlineView isGroupItem: item] ? NO : YES;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldShowOutlineCellForItem: (id) item
{
  NSTreeNode *node = (NSTreeNode *) item;
  
  return [node.representedObject isKindOfClass: [MUProfilesSection class]] ? NO : YES;
}

- (NSView *) outlineView: (NSOutlineView *) outlineView viewForTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  if ([self outlineView: outlineView isGroupItem: item])
    return [outlineView makeViewWithIdentifier: @"HeaderCell" owner: self];
  else
    return [outlineView makeViewWithIdentifier: @"DataCell" owner: self];
}

- (void) outlineViewItemWillCollapse: (NSNotification *) notification
{
  id item = notification.userInfo[@"NSObject"];
  id persistentObject = [self outlineView: profilesOutlineView persistentObjectForItem: item];
  
  if (persistentObject)
    [profilesExpandedItems removeObject: persistentObject];
}

- (void) outlineViewItemWillExpand: (NSNotification *) notification
{
  id item = notification.userInfo[@"NSObject"];
  id persistentObject = [self outlineView: profilesOutlineView persistentObjectForItem: item];
  
  if (persistentObject)
    [profilesExpandedItems addObject: persistentObject];
}

- (void) outlineViewSelectionDidChange: (NSNotification *) notification
{
  if (profilesOutlineView.selectedRow == -1)
  {
    [profileContentView removeAllSubviews];
    return;
  }
  
  NSTreeNode *node = [profilesOutlineView itemAtRow: profilesOutlineView.selectedRow];
  MUTreeNode *representedObject = node.representedObject;
  
	if ([representedObject isKindOfClass: [MUWorld class]])
  {
    MUWorld *world = (MUWorld *) representedObject;
    
    [profileContentView removeAllSubviews];
    
    if (!_worldViewController)
      _worldViewController = [[MUWorldViewController alloc] init];
    
    _worldViewController.world = world;
    
    [profileContentView addSubview: _worldViewController.view];
    
    if (!_profileViewController)
      _profileViewController = [[MUProfileViewController alloc] init];
    
    _profileViewController.profile = [[MUProfileRegistry defaultRegistry] profileForWorld: world];
    
    [profileContentView addSubview: _profileViewController.view];
  }
  else if ([representedObject isKindOfClass: [MUPlayer class]])
  {
    MUPlayer *player = (MUPlayer *) representedObject;
    
    [profileContentView removeAllSubviews];
    
    if (!_playerViewController)
      _playerViewController = [[MUPlayerViewController alloc] init];
    
    _playerViewController.player = player;
    
    if (!_worldViewController)
      _worldViewController = [[MUWorldViewController alloc] init];
    
    _worldViewController.world = (MUWorld *) player.parent;
    
    [profileContentView addSubview: _worldViewController.view];
    [profileContentView addSubview: _playerViewController.view];
    
    if (!_profileViewController)
      _profileViewController = [[MUProfileViewController alloc] init];
    
    _profileViewController.profile = [[MUProfileRegistry defaultRegistry] profileForWorld: (MUWorld *) player.parent
                                                                                   player: player];
    
    [profileContentView addSubview: _profileViewController.view];
  }
}

#pragma mark - NSWindowDelegate protocol

- (void) windowDidLoad
{
  [self expandProfilesOutlineView];
}

- (void) windowWillClose: (NSNotification *) notification
{
  [self saveProfilesOutlineViewState];
}

#pragma mark - Private methods

- (void) _applicationWillTerminate: (NSNotification *) notification
{
  [self saveProfilesOutlineViewState];
}

- (void) _registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_applicationWillTerminate:)
                                               name: NSApplicationWillTerminateNotification
                                             object: NSApp];
}

@end

#pragma mark -

@implementation MUProfilesWindowController (TreeController)

- (void) expandProfilesOutlineView
{
  [profilesOutlineView collapseItem: nil collapseChildren: YES];
  
  for (NSInteger i = 0; i < profilesOutlineView.numberOfRows; i++)
  {
    NSTreeNode *node = [profilesOutlineView itemAtRow: i];
    
    if ([((MUTreeNode *) node.representedObject) isKindOfClass: [MUSection class]])
      [profilesOutlineView expandItem: node];
  }
  
  NSArray *stateArray = [[NSUserDefaults standardUserDefaults] arrayForKey: MUPProfilesOutlineViewState];
  
  if (!stateArray)
    return;
  
  for (id stateObject in stateArray)
    [profilesOutlineView expandItem: [self outlineView: profilesOutlineView itemForPersistentObject: stateObject]];
}

- (void) populateProfilesFromWorldRegistry
{
  MUProfilesSection *profilesSection = [[MUProfilesSection alloc] initWithName: @"PROFILES"];
  
  [self willChangeValueForKey: @"profilesTreeArray"];
  [profilesTreeArray addObject: profilesSection];
  [self didChangeValueForKey: @"profilesTreeArray"];
}

- (void) populateProfilesTree
{
  @autoreleasepool
  {
		[self populateProfilesFromWorldRegistry];
	}
}

- (void) saveProfilesOutlineViewState
{
  [[NSUserDefaults standardUserDefaults] setObject: profilesExpandedItems
                                            forKey: MUPProfilesOutlineViewState];
}

@end
