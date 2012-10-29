//
// MUProfilesToolbarController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfilesToolbarController.h"

#import "MUProfilesWindowController.h"

@interface MUProfilesToolbarController ()
{
  NSToolbar *toolbar;
}

@end

#pragma mark -

@implementation MUProfilesToolbarController
{
  NSToolbar *toolbar;
}

- (void) awakeFromNib
{
  toolbar = [[NSToolbar alloc] initWithIdentifier: @"profilesWindowToolbar"];
  [toolbar setDelegate: self];
  [toolbar setAllowsUserCustomization: YES];
  [toolbar setAutosavesConfiguration: YES];
  
  [window setToolbar: toolbar];
}

#pragma mark - NSToolbar delegate

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) flag
{
  NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  if ([itemIdentifier isEqualToString: MUGoToURLToolbarItem])
  {
    item.label = _(MULGoToURL);
    item.paletteLabel = _(MULGoToURL);
    item.image = nil;
    item.target = windowController;
    item.action = @selector (goToWorldURL:);
  }
  
  return item;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
  return @[MUAddWorldToolbarItem,
  	MUAddPlayerToolbarItem,
  	MUEditSelectedRowToolbarItem,
  	MURemoveSelectedRowToolbarItem,
  	MUEditProfileForSelectedRowToolbarItem,
    NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
  return @[NSToolbarSeparatorItemIdentifier,
    NSToolbarSpaceItemIdentifier,
    NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier,
  	MUAddWorldToolbarItem,
  	MUAddPlayerToolbarItem,
  	MUEditSelectedRowToolbarItem,
  	MURemoveSelectedRowToolbarItem,
  	MUEditProfileForSelectedRowToolbarItem,
    MUGoToURLToolbarItem];
}

@end
