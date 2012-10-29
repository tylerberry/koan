//
// MUConnectionToolbarController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUConnectionToolbarController.h"

#import "MUConnectionWindowController.h"

@interface MUConnectionToolbarController ()

@property (strong, nonatomic) NSToolbar *toolbar;

@end

#pragma mark -

@implementation MUConnectionToolbarController

@synthesize toolbar;

- (void) awakeFromNib
{
  self.toolbar = [[NSToolbar alloc] initWithIdentifier: @"connectionWindowToolbar"];
  
  self.toolbar.delegate = self;
  self.toolbar.allowsUserCustomization = YES;
  self.toolbar.autosavesConfiguration = YES;
  
  [window setToolbar: self.toolbar];
  
}

#pragma mark - NSToolbar delegate

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) insertIntoToolbar
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

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar*) toolbar
{
  return @[NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar*) toolbar
{
  return @[NSToolbarSeparatorItemIdentifier,
    NSToolbarSpaceItemIdentifier,
    NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier,
    NSToolbarShowColorsItemIdentifier,
    NSToolbarShowFontsItemIdentifier,
    NSToolbarPrintItemIdentifier,
    MUGoToURLToolbarItem];
}

@end
