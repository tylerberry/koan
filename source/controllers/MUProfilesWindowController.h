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
}

@property (strong) NSMutableArray *profilesTreeArray;

- (IBAction) addNewPlayer: (id) sender;
- (IBAction) addNewWorld: (id) sender;
- (IBAction) goToWorldURL: (id) sender;
- (IBAction) showAddContextMenu: (id) sender;

@end
