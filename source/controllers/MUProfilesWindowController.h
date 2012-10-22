//
// MUProfilesWindowController.h
//
// Copyright (c) 2012 3James Software.
//

@class MUProfileContentView;

@interface MUProfilesWindowController : NSWindowController <NSOutlineViewDelegate, NSSplitViewDelegate, NSWindowDelegate>
{
  IBOutlet NSTreeController *profilesTreeController;
  
  IBOutlet NSSplitView *profilesSplitView;
  
  IBOutlet NSOutlineView *profilesOutlineView;
  IBOutlet NSButton *addButton;
  IBOutlet NSButton *actionButton;
  
  IBOutlet NSScrollView *profileContentScrollView;
  IBOutlet MUProfileContentView *profileContentView;
  
  IBOutlet NSMenu *addMenu;
}

@property  NSMutableArray *profilesTreeArray;

- (IBAction) goToWorldURL: (id) sender;
- (IBAction) showAddContextMenu: (id) sender;

@end
