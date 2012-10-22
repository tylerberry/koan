//
// MUApplicationController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "CTBadge.h"
#import "MUConnectionWindowController.h"

@class MUAcknowledgementsController;
@class MUPreferencesController;
@class MUProfilesWindowController;
@class MUProxySettingsController;

@interface MUApplicationController : NSObject <MUConnectionWindowControllerDelegate>
{
  IBOutlet NSMenu *openConnectionMenu;
  
  IBOutlet NSPanel *newConnectionPanel;
  IBOutlet NSTextField *newConnectionHostnameField;
  IBOutlet NSTextField *newConnectionPortField;
  IBOutlet NSButton *newConnectionSaveWorldButton;
  
  IBOutlet MUPreferencesController *preferencesController;
}

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) connectToURL: (NSURL *) url;
- (IBAction) connectUsingPanelInformation: (id) sender;
- (IBAction) openBugsWebPage: (id) sender;
- (IBAction) openNewConnectionPanel: (id) sender;
- (IBAction) showAboutPanel: (id) sender;
- (IBAction) showAcknowledgementsWindow: (id) sender;
- (IBAction) showPreferencesWindow: (id) sender;
- (IBAction) showProfilesPanel: (id) sender;
- (IBAction) showProxySettings: (id) sender;
- (IBAction) toggleUseProxy: (id) sender;

@end
