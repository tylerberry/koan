//
// MUApplicationController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "CTBadge.h"
#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"

@class MUAcknowledgementsController;
@class MUPreferencesController;
@class MUProfilesWindowController;
@class MUProxySettingsController;

@interface MUApplicationController : NSObject <NSApplicationDelegate, MUConnectPanelControllerDelegate, MUConnectionWindowControllerDelegate>
{
  IBOutlet NSMenu *openConnectionMenu;
  
  IBOutlet MUPreferencesController *preferencesController;
}

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) connectToURL: (NSURL *) url;
- (IBAction) openBugsWebPage: (id) sender;
- (IBAction) showAboutPanel: (id) sender;
- (IBAction) showAcknowledgementsWindow: (id) sender;
- (IBAction) showConnectPanel: (id) sender;
- (IBAction) showPreferencesWindow: (id) sender;
- (IBAction) showProfilesWindow: (id) sender;
- (IBAction) showProxySettings: (id) sender;
- (IBAction) toggleUseProxy: (id) sender;

@end
