//
// MUProfilesWindowController.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUOutlineView.h"

@class MUProfileContentView;

@interface MUProfilesWindowController : NSWindowController <MUOutlineViewDelegate, NSSplitViewDelegate, NSWindowDelegate>
{
  IBOutlet NSTreeController *profilesTreeController;
  
  IBOutlet NSSplitView *profilesSplitView;
  
  IBOutlet MUOutlineView *profilesOutlineView;
  IBOutlet NSButton *addButton;
  IBOutlet NSButton *actionButton;
  
  IBOutlet NSView *firstView;
  IBOutlet NSView *lastView;
  
  IBOutlet MUProfileContentView *profileContentView;
  
  IBOutlet NSMenu *addMenu;
  IBOutlet NSMenu *actionMenu;
}

@property (strong) NSMutableArray *profilesTreeArray;

- (IBAction) addNewPlayer: (id) sender;
- (IBAction) addNewWorld: (id) sender;
- (IBAction) openWebsiteForSelectedProfile: (id) sender;
- (IBAction) openConnectionForSelectedProfile: (id) sender;
- (IBAction) showAddContextMenu: (id) sender;
- (IBAction) showActionContextMenu: (id) sender;

@end
