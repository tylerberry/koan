//
// MUApplicationController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"

@class MUPreferencesController;

@interface MUApplicationController : NSObject <NSApplicationDelegate, MUConnectPanelControllerDelegate, MUConnectionWindowControllerDelegate>
{
  IBOutlet NSMenu *openConnectionMenu;
}

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) connectToURL: (NSURL *) url;
- (IBAction) showProxySettings: (id) sender;
- (IBAction) toggleUseProxy: (id) sender;

- (IBAction) openBugsWebPage: (id) sender;
- (IBAction) showAboutPanel: (id) sender;
- (IBAction) showAcknowledgementsWindow: (id) sender;
- (IBAction) showConnectPanel: (id) sender;
- (IBAction) showPreferencesWindow: (id) sender;
- (IBAction) showProfilesWindow: (id) sender;


@end
