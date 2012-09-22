//
// MUConnectionToolbarController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUConnectionToolbarController : NSObject <NSToolbarDelegate>

@property (weak, readonly) IBOutlet NSWindow *window;
@property (weak, readonly) IBOutlet NSWindowController *windowController;

@end
