//
// UKPrefsPanel.h
//
// Copyright (c) 2003-2005 M. Uli Kusterer. All rights reserved.
//
// License:
//
//   You may redistribute, modify, use in commercial products free of charge,
//   however distributing modified copies requires that you clearly mark them
//   as having been modified by you, while maintaining the original markings
//   and copyrights. I don't like getting bug reports about code I wasn't
//   involved in.
//
//   I'd also appreciate if you gave credit in your app's about screen or a
//   similar place. A simple "Thanks to M. Uli Kusterer" is quite sufficient.
//   Also, I rarely turn down any postcards, gifts, complementary copies of
//   applications etc.
//
// Modifications by Tyler Berry.
// Copyright (c) 2012 3James Software.
//

#import "UKPrefsPanel.h"

@interface UKPrefsPanel (Private)

- (IBAction) changePanes: (id) sender;
- (void) mapTabsToToolbar;

@end

#pragma mark -

@implementation UKPrefsPanel

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  tabView = nil;
  itemsList = [[NSMutableDictionary alloc] init];
  baseWindowName = @"";
  autosaveName = @"com.ulikusterer";
  
  return self;
}


- (void) awakeFromNib
{
  NSString *windowTitle = tabView.window.title;

  if (windowTitle.length > 0)
  	baseWindowName = [NSString stringWithFormat: @"%@ : ", windowTitle];
  
  self.autosaveName = tabView.window.frameAutosaveName;
  
  NSString *key = [NSString stringWithFormat: @"%@.prefspanel.recentpage", autosaveName];
  NSInteger tabIndex = [[NSUserDefaults standardUserDefaults] integerForKey: key];
  [tabView selectTabViewItemAtIndex: tabIndex];
  
  [self mapTabsToToolbar];
}

#pragma mark - Accessors

- (NSTabView *) tabView
{
  return tabView;
}

- (void) setTabView: (NSTabView *) view
{
  tabView = view;
}

- (NSString *) autosaveName
{
  return autosaveName;
}

- (void) setAutosaveName: (NSString *) name
{
  if (autosaveName == name)
    return;
  
  autosaveName = name;
}

#pragma mark - Actions

- (IBAction) orderFrontPrefsPanel: (id) sender
{
  [tabView.window makeKeyAndOrderFront: sender];
}

#pragma mark - NSToolbar delegate

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) willBeInserted
{
  NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  NSString *itemLabel = itemsList[itemIdentifier];
  
  if (itemLabel)
  {
  	toolbarItem.label = itemLabel;
  	toolbarItem.paletteLabel = itemLabel;
  	toolbarItem.tag = [tabView indexOfTabViewItemWithIdentifier: itemIdentifier];
  	toolbarItem.toolTip = itemLabel;
  	toolbarItem.image = [NSImage imageNamed: itemIdentifier];
  	toolbarItem.target = self;
  	toolbarItem.action = @selector (changePanes:);
  }
  else
  	toolbarItem = nil;
  
  return toolbarItem;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar
{
  return itemsList.allKeys;
}

#endif

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
  NSMutableArray *defaultItems = [NSMutableArray array];
  
  for (NSInteger i = 0; i < tabView.numberOfTabViewItems; i++)
  {
  	[defaultItems addObject: [tabView tabViewItemAtIndex: i].identifier];
  }
  
  return defaultItems;
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
  NSMutableArray *allowedItems = [[itemsList allKeys] mutableCopy];
  
  [allowedItems addObjectsFromArray: @[NSToolbarSeparatorItemIdentifier,
    NSToolbarSpaceItemIdentifier,
    NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier]];
  
  return allowedItems;
}

@end

#pragma mark -

@implementation UKPrefsPanel (Private)

- (IBAction) changePanes: (id) sender
{
  NSToolbarItem *toolbarItem = (NSToolbarItem *) sender;
  
  [tabView selectTabViewItemAtIndex: toolbarItem.tag];
  [[tabView window] setTitle: [baseWindowName stringByAppendingString: toolbarItem.label]];
  
  NSString *key = [NSString stringWithFormat:  @"%@.prefspanel.recentpage", autosaveName];
  [[NSUserDefaults standardUserDefaults] setInteger: toolbarItem.tag forKey: key];
}

- (void) mapTabsToToolbar
{
  NSToolbar *toolbar = [[tabView window] toolbar];
  
  if (!toolbar)
  	toolbar = [[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat: @"%@.prefspanel.toolbar",
                                                      autosaveName]];
  
  toolbar.allowsUserCustomization = YES;
  toolbar.autosavesConfiguration = YES;
  toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
  
  [itemsList removeAllObjects];
  
  for (NSInteger i = 0; i < tabView.numberOfTabViewItems; i++)
  {
  	itemsList[[tabView tabViewItemAtIndex: i].identifier] = [tabView tabViewItemAtIndex: i].label;
  }
  
  toolbar.delegate = self ;
  
  tabView.window.toolbar = toolbar;
  
  
  NSTabViewItem	*currentTab = tabView.selectedTabViewItem;
  if (currentTab == nil)
  	currentTab = [tabView tabViewItemAtIndex: 0];
  
  tabView.window.title = [baseWindowName stringByAppendingString: currentTab.label];
  
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
  
  if ([toolbar respondsToSelector: @selector (setSelectedItemIdentifier:)])
  	[toolbar setSelectedItemIdentifier: currentTab.identifier];
  
#endif
}

@end
