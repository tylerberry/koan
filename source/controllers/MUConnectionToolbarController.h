//
// MUConnectionToolbarController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUConnectionToolbarController : NSObject <NSToolbarDelegate>
{
  NSToolbar *toolbar;
  
  IBOutlet NSWindow *window;
  IBOutlet NSWindowController *windowController;
}

@end
