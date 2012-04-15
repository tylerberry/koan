//
// MUProfilesController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUProfile;
@class MUWorldRegistry;

@interface MUProfilesController : NSWindowController
{
  NSMutableArray *profilesTreeArray;
  NSMutableArray *profilesExpandedItems;
  
  IBOutlet NSTreeController *profilesTreeController;
  IBOutlet NSOutlineView *profilesOutlineView;
  
  BOOL backgroundColorActive;
  BOOL linkColorActive;
  BOOL textColorActive;
  BOOL visitedLinkColorActive;
  
  MUProfile *editingProfile;
  NSFont *editingFont;
}

@property  NSMutableArray *profilesTreeArray;

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) goToWorldURL: (id) sender;

@end
