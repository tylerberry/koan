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
#import "MUWorldRegistry.h"
#import "MUWorldViewController.h"

@interface MUProfilesWindowController ()
{
  NSMutableArray *_profilesExpandedItems;
  NSUndoManager *_undoManager;
  
  MUPlayerViewController *_playerViewController;
  MUProfileViewController *_profileViewController;
  MUWorldViewController *_worldViewController;
}

- (void) _applicationWillTerminate: (NSNotification *) notification;
- (void) _registerForNotifications;

#pragma mark - Tree controller handling

- (void) _addNode: (MUTreeNode *) node atIndexPath: (NSIndexPath *) indexPath;
- (void) _deleteNodeAtIndexPath: (NSIndexPath *) indexPath;
- (void) _expandProfilesOutlineView;
- (void) _populateProfilesFromWorldRegistry;
- (void) _populateProfilesTree;
- (void) _saveProfilesOutlineViewState;

@end

#pragma mark -

@implementation MUProfilesWindowController

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUProfilesWindow" owner: self]))
    return nil;
  
  _profilesTreeArray = [[NSMutableArray alloc] init];
  _profilesExpandedItems = [[NSMutableArray alloc] init];
  
  _undoManager = [[NSUndoManager alloc] init];
  
  _playerViewController = nil;
  _profileViewController = nil;
  _worldViewController = nil;
  
  [self _populateProfilesTree];
  
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

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if ([object isKindOfClass: [MUProfilesSection class]] && [keyPath isEqualToString: @"children"])
  {
    [self willChangeValueForKey: @"profilesTreeArray"];
    [self didChangeValueForKey: @"profilesTreeArray"];
    return;
  }
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

#pragma mark - Actions

- (IBAction) addNewPlayer: (id) sender
{
  NSIndexPath *selectionIndexPath = profilesTreeController.selectionIndexPath;
  NSIndexPath *newIndexPath;
  
  if (selectionIndexPath)
  {
    NSArray *selectedObjects = profilesTreeController.selectedObjects;
    
    if (selectedObjects.count == 0)
      return;
    else if (selectedObjects.count > 1)
    {
      NSLog (@"Warning: Logic error: more than one row selected in profiles outline view.");
      return;
    }
    
    MUTreeNode *node = selectedObjects[0];
    
    if ([node isKindOfClass: [MUWorld class]])
    {
      // Construct the index path at the end of the selected world's children.
      
      NSUInteger numberOfIndexes = selectionIndexPath.length + 1;
      NSUInteger indexes[numberOfIndexes];
      
      [selectionIndexPath getIndexes: indexes];
      
      indexes[numberOfIndexes - 1] = ((MUWorld *) node).children.count;
      
      newIndexPath = [NSIndexPath indexPathWithIndexes: indexes length: numberOfIndexes];
    }
    else if ([node isKindOfClass: [MUPlayer class]])
    {
      // Construct the index path after the selected player.
      
      NSUInteger numberOfIndexes = selectionIndexPath.length;
      NSUInteger indexes[numberOfIndexes];
      
      [selectionIndexPath getIndexes: indexes];
      
      indexes[numberOfIndexes - 1]++;
      
      newIndexPath = [NSIndexPath indexPathWithIndexes: indexes length: numberOfIndexes];
    }
    else
    {
      NSLog (@"Warning: Logic error: MUProfilesWindowController -addNewPlayer: called with unknown selection class.");
      return;
    }
  }
  else
  {
    NSLog (@"Warning: Logic error: MUProfilesWindowController -addNewPlayer: called with no selection.");
    return;
  }
  
  [self _addNode: [[MUPlayer alloc] init] atIndexPath: newIndexPath];
  _undoManager.actionName = _(MUUndoAddPlayer);
}

- (IBAction) addNewWorld: (id) sender
{
  NSIndexPath *selectionIndexPath = profilesTreeController.selectionIndexPath;
  NSIndexPath *newIndexPath;
  
  if (selectionIndexPath)
  {
    NSArray *selectedObjects = profilesTreeController.selectedObjects;
    
    if (selectedObjects.count == 0)
      return;
    else if (selectedObjects.count > 1)
    {
      NSLog (@"Warning: Logic error: more than one row selected in profiles outline view.");
      return;
    }
    
    MUTreeNode *node = selectedObjects[0];
    
    if ([node isKindOfClass: [MUWorld class]])
    {
      // Construct the index path after the selected world.
      
      NSUInteger numberOfIndexes = selectionIndexPath.length;
      NSUInteger indexes[numberOfIndexes];
    
      [selectionIndexPath getIndexes: indexes];
    
      indexes[numberOfIndexes - 1]++;
    
      newIndexPath = [NSIndexPath indexPathWithIndexes: indexes length: numberOfIndexes];
    }
    else if ([node isKindOfClass: [MUPlayer class]])
    {
      // Construct the index path pointing after the selected player's parent.
      
      NSUInteger numberOfIndexes = selectionIndexPath.length;
      NSUInteger indexes[numberOfIndexes];
      
      [selectionIndexPath getIndexes: indexes];
      
      indexes[numberOfIndexes - 2]++;
      
      newIndexPath = [NSIndexPath indexPathWithIndexes: indexes length: numberOfIndexes - 1];
    }
    else
    {
      NSLog (@"Warning: Logic error: MUProfilesWindowController -addNewWorld: called with unknown selection class.");
      return;
    }
  }
  else
  {
    // Construct the index path pointing to the top level of the world registry at the end.
    
    NSUInteger indexes[2] = {0, [MUWorldRegistry defaultRegistry].worlds.count};
    newIndexPath = [NSIndexPath indexPathWithIndexes: indexes length: 2];
  }
  
  [self _addNode: [[MUWorld alloc] init] atIndexPath: newIndexPath];
  _undoManager.actionName = _(MUUndoAddWorld);
}

- (IBAction) openConnectionForSelectedProfile: (id) sender
{
  return;
}

- (IBAction) openWebsiteForSelectedProfile: (id) sender
{
  return;
}

- (IBAction) showAddContextMenu: (id) sender
{
  if (!profilesTreeController.selectionIndexPath)
  {
    [self addNewWorld: sender];
  }
  else
  {
    [NSMenu popUpContextMenu: addMenu
                   withEvent: [NSEvent mouseEventWithType: NSLeftMouseUp
                                                 location: addButton.frame.origin
                                            modifierFlags: 0
                                                timestamp: NSTimeIntervalSince1970
                                             windowNumber: self.window.windowNumber
                                                  context: nil
                                              eventNumber: 0
                                               clickCount: 1
                                                 pressure: 1.0]
                     forView: addButton];
  }
}

- (IBAction) showActionContextMenu: (id) sender
{
  [NSMenu popUpContextMenu: actionMenu
                 withEvent: [NSEvent mouseEventWithType: NSLeftMouseUp
                                               location: actionButton.frame.origin
                                          modifierFlags: 0
                                              timestamp: NSTimeIntervalSince1970
                                           windowNumber: self.window.windowNumber
                                                context: nil
                                            eventNumber: 0
                                             clickCount: 1
                                               pressure: 1.0]
                   forView: actionButton];
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
    
    for (NSUInteger i = 0; i < items.count; i++) // Don't change this to fast enumeration.
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
  return ((MUTreeNode *) ((NSTreeNode *) item).representedObject).uniqueIdentifier;
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
    [_profilesExpandedItems removeObject: persistentObject];
}

- (void) outlineViewItemWillExpand: (NSNotification *) notification
{
  id item = notification.userInfo[@"NSObject"];
  id persistentObject = [self outlineView: profilesOutlineView persistentObjectForItem: item];
  
  if (persistentObject)
    [_profilesExpandedItems addObject: persistentObject];
}

- (void) outlineViewSelectionDidChange: (NSNotification *) notification
{
  if (profilesOutlineView.selectedRow == -1)
  {
    [profileContentView removeAllSubviews];
    lastView.nextKeyView = firstView;
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
    
    lastView.nextKeyView = _worldViewController.firstView;
    _worldViewController.lastView.nextKeyView = _profileViewController.firstView;
    _profileViewController.lastView.nextKeyView = firstView;
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
    
    lastView.nextKeyView = _worldViewController.firstView;
    _worldViewController.lastView.nextKeyView = _playerViewController.firstView;
    _playerViewController.lastView.nextKeyView = _profileViewController.firstView;
    _profileViewController.lastView.nextKeyView = firstView;
  }
}

#pragma mark - MUOutlineViewDelegate protocol

- (BOOL) outlineView: (NSOutlineView *) outlineView keyDown: (NSEvent *) event
{
  NSString *characters = event.characters;
  if ([characters characterAtIndex: 0] == NSDeleteCharacter || [characters characterAtIndex: 0] == NSBackspaceCharacter)
  {
    if (profilesTreeController.selectionIndexPath)
    {
      NSArray *selectedObjects = profilesTreeController.selectedObjects;
      
      if (selectedObjects.count > 1)
      {
        NSLog (@"Warning: Logic error: more than one row selected in profiles outline view.");
        return YES;
      }
      
      MUTreeNode *node = selectedObjects[0];
      
      if ([node isKindOfClass: [MUWorld class]])
      {
        [self _deleteNodeAtIndexPath: profilesTreeController.selectionIndexPath];
        _undoManager.actionName = _(MUUndoDeleteWorld);
      }
      else if ([node isKindOfClass: [MUPlayer class]])
      {
        [self _deleteNodeAtIndexPath: profilesTreeController.selectionIndexPath];
        _undoManager.actionName = _(MUUndoDeletePlayer);
      }
    }
    return YES;
  }
  return NO;
}

#pragma mark - NSSplitViewDelegate protocol



#pragma mark - NSWindowDelegate protocol

- (void) windowDidLoad
{
  [self _expandProfilesOutlineView];
}

- (void) windowWillClose: (NSNotification *) notification
{
  [self _saveProfilesOutlineViewState];
}

- (NSUndoManager *) windowWillReturnUndoManager: (NSWindow *) window
{
  return _undoManager;
}

#pragma mark - Private methods

- (void) _applicationWillTerminate: (NSNotification *) notification
{
  [self _saveProfilesOutlineViewState];
}

- (void) _registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (_applicationWillTerminate:)
                                               name: NSApplicationWillTerminateNotification
                                             object: NSApp];
}

#pragma mark - Tree controller handling

- (void) _addNode: (MUTreeNode *) node atIndexPath: (NSIndexPath *) indexPath
{
  [profilesTreeController insertObject: node atArrangedObjectIndexPath: indexPath];
  
  [[_undoManager prepareWithInvocationTarget: self] _deleteNodeAtIndexPath: indexPath];
}

- (void) _deleteNodeAtIndexPath: (NSIndexPath *) indexPath
{
  NSArray *selectedObjects = profilesTreeController.selectedObjects;
  
  if (selectedObjects.count == 0)
    return;
  else if (selectedObjects.count > 1)
  {
    NSLog (@"Warning: Logic error: more than one row selected in profiles outline view.");
    return;
  }
  
  MUTreeNode *node = selectedObjects[0];
  
  BOOL savedAvoidsEmptySelection = profilesTreeController.avoidsEmptySelection;
  profilesTreeController.avoidsEmptySelection = YES;
  
  [profilesTreeController removeObjectAtArrangedObjectIndexPath: indexPath];
  
  profilesTreeController.avoidsEmptySelection = savedAvoidsEmptySelection;
  
  [[_undoManager prepareWithInvocationTarget: self] _addNode: node atIndexPath: indexPath];
}

- (void) _expandProfilesOutlineView
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

- (void) _populateProfilesFromWorldRegistry
{
  MUProfilesSection *profilesSection = [[MUProfilesSection alloc] initWithName: @"PROFILES"];
  
  [self willChangeValueForKey: @"profilesTreeArray"];
  [_profilesTreeArray addObject: profilesSection];
  [profilesSection addObserver: self forKeyPath: @"children" options: 0 context: nil];
  [self didChangeValueForKey: @"profilesTreeArray"];
}

- (void) _populateProfilesTree
{
  @autoreleasepool
  {
		[self _populateProfilesFromWorldRegistry];
	}
}

- (void) _saveProfilesOutlineViewState
{
  [[NSUserDefaults standardUserDefaults] setObject: _profilesExpandedItems
                                            forKey: MUPProfilesOutlineViewState];
}

@end
