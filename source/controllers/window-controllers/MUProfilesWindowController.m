//
// MUProfilesWindowController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUPlayerViewController.h"
#import "MUProfilesWindowController.h"
#import "MUProfile.h"
#import "MUProfileContentView.h"
#import "MUProfileRegistry.h"
#import "MUProfileViewController.h"
#import "MUProfilesSection.h"
#import "MUSection.h"
#import "MUWorldRegistry.h"
#import "MUWorldViewController.h"

#import "ATImageTextCell.h"
#import "NSTreeController+IndexPaths.h"

@interface MUProfilesWindowController ()
{
  NSMutableArray *_profilesExpandedItems;
  NSUndoManager *_undoManager;
  
  NSArray *_draggedNodes;
  
  MUPlayerViewController *_playerViewController;
  MUProfileViewController *_profileViewController;
  MUWorldViewController *_worldViewController;
}

- (void) _applicationWillTerminate: (NSNotification *) notification;
- (NSDragOperation) _dragOperationForOutlineView: (NSOutlineView *) outlineView
                                    draggingInfo: (id <NSDraggingInfo>) draggingInfo;
- (void) _registerForNotifications;

#pragma mark - Tree controller handling

- (void) _addNode: (MUTreeNode *) node atIndexPath: (NSIndexPath *) indexPath;
- (void) _deleteNodeAtIndexPath: (NSIndexPath *) indexPath;
- (void) _expandProfilesOutlineView;
- (void) _moveNode: (NSTreeNode *) node toIndexPath: (NSIndexPath *) indexPath;
- (void) _openConnectionForTreeNode: (MUTreeNode *) treeNode;
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
  
  profilesOutlineView.target = self;
  profilesOutlineView.doubleAction = @selector (openConnectionForDoubleClickedProfile:);
  
  [profilesOutlineView registerForDraggedTypes: @[MUWorldPasteboardType, MUPlayerPasteboardType]];
  
  [profilesOutlineView setDraggingSourceOperationMask: (NSDragOperationCopy | NSDragOperationMove)
                                             forLocal: YES];
  [profilesOutlineView setDraggingSourceOperationMask: NSDragOperationCopy
                                             forLocal: NO];
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

- (IBAction) openConnectionForDoubleClickedProfile: (id) sender
{
  NSTreeNode *node = [profilesOutlineView itemAtRow: profilesOutlineView.clickedRow];
  
  [self _openConnectionForTreeNode: (MUTreeNode *) node.representedObject];
}

- (IBAction) openConnectionForSelectedProfile: (id) sender
{
  NSArray *selectedObjects = profilesTreeController.selectedObjects;
  
  if (selectedObjects.count == 0)
    return;
  else if (selectedObjects.count > 1)
  {
    NSLog (@"Warning: Logic error: more than one row selected in profiles outline view.");
    return;
  }
  
  [self _openConnectionForTreeNode: (MUTreeNode *) selectedObjects[0]];
}

- (IBAction) openWebsiteForSelectedProfile: (id) sender
{
  NSArray *selectedObjects = profilesTreeController.selectedObjects;
  
  if (selectedObjects.count == 0)
    return;
  else if (selectedObjects.count > 1)
  {
    NSLog (@"Warning: Logic error: more than one row selected in profiles outline view.");
    return;
  }
  
  MUTreeNode *node = (MUTreeNode *) selectedObjects[0];
  
  if ([node isKindOfClass: [MUWorld class]])
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: ((MUWorld *) node).url]];
  else if ([node isKindOfClass: [MUPlayer class]])
  {
    MUPlayer *player = (MUPlayer *) node;
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: player.world.url]];
  }
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

- (IBAction) changeProfileFont: (id) sender
{
  if (_profileViewController.profile.font == nil)
  {
    // If profile.font is nil, then we don't handle this message.
    // TODO: Is this really the behavior we want?
    return;
  }
  
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = fontManager.selectedFont;
  
  if (selectedFont == nil)
    selectedFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  NSFont *convertedFont = [fontManager convertFont: selectedFont];
  
  _profileViewController.profile.font = convertedFont;
}

#pragma mark - NSOutlineView data source

- (BOOL) outlineView: (NSOutlineView *) outlineView
          acceptDrop: (id <NSDraggingInfo>) draggingInfo
                item: (id) targetItem
          childIndex: (NSInteger) childIndex
{
  NSArray *typesArray = @[MUWorldPasteboardType, MUPlayerPasteboardType];
  NSString *availableType = [draggingInfo.draggingPasteboard availableTypeFromArray: typesArray];
  
  if (!availableType)
    return NO;
  
  NSIndexPath *newNodeIndexPath;
  
  if (targetItem)
  {
    [outlineView expandItem: targetItem];
    
    NSIndexPath *baseIndexPath = [profilesTreeController indexPathOfTreeNode: targetItem];
    newNodeIndexPath = [baseIndexPath indexPathByAddingIndex: childIndex];
  }
  else
    newNodeIndexPath = [[NSIndexPath alloc] initWithIndex: childIndex];
  
  if (draggingInfo.draggingSource == outlineView
      && [self _dragOperationForOutlineView: outlineView draggingInfo: draggingInfo] == NSDragOperationMove)
  {
    for (NSTreeNode *node in _draggedNodes)
    {
      BOOL shouldExpand = [outlineView isItemExpanded: node];
      
      [self _moveNode: node toIndexPath: newNodeIndexPath];
      
      if (shouldExpand)
        [outlineView expandItem: node];
    }
    
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    
    for (NSTreeNode *node in _draggedNodes)
    {
      [indexSet addIndex: [outlineView rowForItem: node]];
    }
    
    [outlineView selectRowIndexes: indexSet byExtendingSelection: NO];
  }
  else // NSDragOperationCopy
  {
    NSData *pasteboardData = [draggingInfo.draggingPasteboard dataForType: availableType];
    NSArray *newNodes = [NSKeyedUnarchiver unarchiveObjectWithData: pasteboardData];
    
    // Add the new items (we do this backwards, otherwise they will end up in reverse order).
    
    for (NSInteger i = newNodes.count - 1; i >= 0; i--)
    {
      [newNodes[i] createNewUniqueIdentifier];
        
      [self _addNode: newNodes[i] atIndexPath: newNodeIndexPath];
        
      NSTreeNode *node = [self outlineView: outlineView
                   itemForPersistentObject: [newNodes[i] uniqueIdentifier]];
      
      [outlineView expandItem: node]; // Somewhat arbitrarily, we expand the copy.
    }
    
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    
    for (NSInteger i = [outlineView rowForItem: targetItem]; i < outlineView.numberOfRows; i++)
    {
      if ([newNodes containsObject: ((NSTreeNode *) [outlineView itemAtRow: i]).representedObject])
        [indexSet addIndex: i];
    }
    
    [outlineView selectRowIndexes: indexSet byExtendingSelection: NO];
  }
  
  return YES;
}

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

- (NSDragOperation) outlineView: (NSOutlineView *) outlineView
                   validateDrop: (id <NSDraggingInfo>) draggingInfo
                   proposedItem: (id) proposedItem
             proposedChildIndex: (NSInteger) proposedChildIndex
{
  MUTreeNode *proposedNode = (MUTreeNode *) ((NSTreeNode *) proposedItem).representedObject;
  
  if (([draggingInfo.draggingPasteboard availableTypeFromArray: @[MUWorldPasteboardType]]
       && [proposedNode isKindOfClass: [MUSection class]])
      || ([draggingInfo.draggingPasteboard availableTypeFromArray: @[MUPlayerPasteboardType]]
          && [proposedNode isKindOfClass: [MUWorld class]]))
  {
    if (proposedChildIndex == -1)  // Onto an object
    {
      // Make the index it will go to explicit.
      [outlineView setDropItem: proposedItem dropChildIndex: 0];
    }
    
    return [self _dragOperationForOutlineView: outlineView draggingInfo: draggingInfo];
  }
  
  return NSDragOperationNone;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView
          writeItems: (NSArray *) items
        toPasteboard: (NSPasteboard *) pasteboard
{
  MUTreeNode *firstNode = (MUTreeNode *) ((NSTreeNode *) items[0]).representedObject;
  NSString *pasteboardType;
  
  if ([firstNode isKindOfClass: [MUWorld class]])
    pasteboardType = MUWorldPasteboardType;
  else if ([firstNode isKindOfClass: [MUPlayer class]])
    pasteboardType = MUPlayerPasteboardType;
  else
    return NO;
  
  NSMutableArray *nodes = [NSMutableArray arrayWithCapacity: items.count];
  NSMutableArray *representedNodes = [NSMutableArray arrayWithCapacity: items.count];
  
  for (NSTreeNode *node in items)
  {
    MUTreeNode *representedNode = (MUTreeNode *) node.representedObject;
    [nodes addObject: node];
    [representedNodes addObject: representedNode];
  }
  
  [pasteboard setData: [NSKeyedArchiver archivedDataWithRootObject: representedNodes]
              forType: pasteboardType];
  
  _draggedNodes = nodes;
  
  return YES;
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

/*
 - (NSView *) outlineView: (NSOutlineView *) outlineView viewForTableColumn: (NSTableColumn *) tableColumn item: (id) item
 {
 if ([self outlineView: outlineView isGroupItem: item])
 return [outlineView makeViewWithIdentifier: @"HeaderCell" owner: self];
 else
 return [outlineView makeViewWithIdentifier: @"DataCell" owner: self];
 }
 */

- (void) outlineView: (NSOutlineView *) outlineView
     willDisplayCell: (id) cell
      forTableColumn: (NSTableColumn *) tableColumn
                item: (id) item
{
  ATImageTextCell *imageTextCell = (ATImageTextCell *) cell;
  NSTreeNode *node = (NSTreeNode *) item;
  MUTreeNode *representedNode = (MUTreeNode *) node.representedObject;
  
  imageTextCell.image = representedNode.icon;
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
    
    _worldViewController.world = player.world;
    
    [profileContentView addSubview: _worldViewController.view];
    [profileContentView addSubview: _playerViewController.view];
    
    if (!_profileViewController)
      _profileViewController = [[MUProfileViewController alloc] init];
    
    _profileViewController.profile = [[MUProfileRegistry defaultRegistry] profileForWorld: player.world
                                                                                   player: player];
    
    [profileContentView addSubview: _profileViewController.view];
    
    lastView.nextKeyView = _worldViewController.firstView;
    _worldViewController.lastView.nextKeyView = _playerViewController.firstView;
    _playerViewController.lastView.nextKeyView = _profileViewController.firstView;
    _profileViewController.lastView.nextKeyView = firstView;
  }
  
  // Sync font panel with new selection.
  
  if (_profileViewController.profile.font)
    [[NSFontManager sharedFontManager] setSelectedFont: _profileViewController.profile.font isMultiple: NO];
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

- (void) windowDidBecomeKey: (NSNotification *) notification
{
  // Keep the font panel in sync with the current key window.
  
  if (_profileViewController.profile.font)
    [[NSFontManager sharedFontManager] setSelectedFont: _profileViewController.profile.font isMultiple: NO];
}

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

- (NSDragOperation) _dragOperationForOutlineView: (NSOutlineView *) outlineView
                                    draggingInfo: (id <NSDraggingInfo>) draggingInfo
{
  if (draggingInfo.draggingSource == outlineView)
  {
    if (draggingInfo.draggingSourceOperationMask & NSDragOperationMove)
      return NSDragOperationMove;
    else
      return NSDragOperationCopy;
  }
  else
    return NSDragOperationCopy;
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

- (void) _moveNode: (NSTreeNode *) node toIndexPath: (NSIndexPath *) indexPath
{
  NSIndexPath *oldIndexPath = [profilesTreeController indexPathOfTreeNode: node];
  
  [profilesTreeController moveNode: node toIndexPath: indexPath];
  
  [[_undoManager prepareWithInvocationTarget: self] _moveNode: node toIndexPath: oldIndexPath];
}

- (void) _openConnectionForTreeNode: (MUTreeNode *) treeNode
{
  if ([treeNode isKindOfClass: [MUWorld class]])
    [self.delegate openConnectionForProfile: [[MUProfileRegistry defaultRegistry] profileForWorld: (MUWorld *) treeNode]];
  else if ([treeNode isKindOfClass: [MUPlayer class]])
  {
    MUPlayer *player = (MUPlayer *) treeNode;
    [self.delegate openConnectionForProfile: [[MUProfileRegistry defaultRegistry] profileForWorld: player.world
                                                                                           player: player]];
  }
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
