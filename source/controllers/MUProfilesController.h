//
// MUProfilesController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUProfile;
@class MUWorldRegistry;

@interface MUProfilesController : NSWindowController <NSOutlineViewDelegate>
{
  IBOutlet NSTreeController *profilesTreeController;
  IBOutlet NSOutlineView *profilesOutlineView;
  IBOutlet NSButton *addButton;
  IBOutlet NSButton *actionButton;
  
  IBOutlet NSMenu *addMenu;
}

@property  NSMutableArray *profilesTreeArray;

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) goToWorldURL: (id) sender;
- (IBAction) showAddContextMenu: (id) sender;

@end
