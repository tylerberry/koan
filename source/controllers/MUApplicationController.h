//
// MUApplicationController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"
#import "MUProfilesWindowController.h"

@class MUPreferencesController;

@interface MUApplicationController : NSObject <NSApplicationDelegate, MUConnectPanelControllerDelegate, MUConnectionWindowControllerDelegate, MUProfilesWindowControllerDelegate>
{
  IBOutlet NSMenu *openConnectionMenu;
}

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) connectToURL: (NSURL *) url;

- (IBAction) openBugsWebPage: (id) sender;
- (IBAction) showAboutPanel: (id) sender;
- (IBAction) showAcknowledgementsWindow: (id) sender;
- (IBAction) showConnectPanel: (id) sender;
- (IBAction) showPreferencesWindow: (id) sender;
- (IBAction) showProfilesWindow: (id) sender;


@end
