//
// MUProfilesWindowController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUOutlineView.h"

@class MUProfile;
@class MUProfileContentView;

@protocol MUProfilesWindowControllerDelegate

@required
- (void) openConnectionForProfile: (MUProfile *) profile;

@end

#pragma mark -

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

@property (weak) NSObject <MUProfilesWindowControllerDelegate> *delegate;
@property (strong) NSMutableArray *profilesTreeArray;

- (IBAction) addNewPlayer: (id) sender;
- (IBAction) addNewWorld: (id) sender;
- (IBAction) openWebsiteForSelectedProfile: (id) sender;
- (IBAction) openConnectionForDoubleClickedProfile: (id) sender;
- (IBAction) openConnectionForSelectedProfile: (id) sender;
- (IBAction) showAddContextMenu: (id) sender;
- (IBAction) showActionContextMenu: (id) sender;

@end
