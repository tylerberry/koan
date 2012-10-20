//
// MUProfilesToolbarController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfilesToolbarController.h"

#import "MUProfilesController.h"

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
  
  if ([itemIdentifier isEqualToString: MUAddWorldToolbarItem])
  {
  	item.label = _(MULAddWorld);
  	item.paletteLabel = _(MULAddWorld);
  	item.image = nil;
  	item.target = windowController;
    //item.action = @selector (addWorld:);
  }
  else if ([itemIdentifier isEqualToString: MUAddPlayerToolbarItem])
  {
  	item.label = _(MULAddPlayer);
  	item.paletteLabel = _(MULAddPlayer);
  	item.image = nil;
  	item.target = windowController;
  	//item.action = @selector (addPlayer:);
  }
  else if ([itemIdentifier isEqualToString: MUEditSelectedRowToolbarItem])
  {
  	item.label = _(MULEditItem);
  	item.paletteLabel = _(MULEditItem);
  	item.image = nil;
  	item.target = windowController;
  	//item.action = @selector (editSelectedRow:);
  }
  else if ([itemIdentifier isEqualToString: MURemoveSelectedRowToolbarItem])
  {
  	item.label = _(MULRemoveItem);
  	item.paletteLabel = _(MULRemoveItem);
  	item.image = nil;
  	item.target = windowController;
  	//item.action = @selector (removeSelectedRow:);
  }
  else if ([itemIdentifier isEqualToString: MUEditProfileForSelectedRowToolbarItem])
  {
  	item.label = _(MULEditProfile);
  	item.paletteLabel = _(MULEditProfile);
  	item.image = nil;
  	item.target = windowController;
  	//item.action = @selector (editProfileForSelectedRow:);
  }
  else if ([itemIdentifier isEqualToString: MUGoToURLToolbarItem])
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
