//
// MUConnectionToolbarController.h
//
// Copyright (c) 2007 3James Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MUConnectionToolbarController : NSObject
{
  NSToolbar *toolbar;
  
  IBOutlet NSWindow *window;
  IBOutlet NSWindowController *windowController;
}

@end
