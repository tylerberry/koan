//
// MUApplicationController.h
//
// Copyright (c) 2004, 2005 3James Software
//

#import <Cocoa/Cocoa.h>

@class MUPreferencesController;
@class MUProfilesController;
@class MUUpdateController;

@interface MUApplicationController : NSObject
{
  IBOutlet NSMenu *openConnectionMenu;
  IBOutlet NSMenuItem *useProxyMenuItem;
  
	IBOutlet NSPanel *newConnectionPanel;
	IBOutlet NSTextField *newConnectionHostnameField;
	IBOutlet NSTextField *newConnectionPortField;
	IBOutlet NSButton *newConnectionSaveWorldButton;
  
  IBOutlet MUUpdateController *updateController;
  IBOutlet MUPreferencesController *preferencesController;
  
  unsigned unreadCount;
  
  NSMutableArray *connectionWindowControllers;
  MUProfilesController *profilesController;
  BOOL useProxy;
}

- (IBAction) chooseNewFont:(id)sender;
- (IBAction) connectToURL:(NSURL *)url;
- (IBAction) connectUsingPanelInformation:(id)sender;
- (IBAction) openBugsWebPage:(id)sender;
- (IBAction) openNewConnectionPanel:(id)sender;
- (IBAction) showPreferencesPanel:(id)sender;
- (IBAction) showProfilesPanel:(id)sender;
- (IBAction) showProxySettings:(id)sender;
- (IBAction) toggleUseProxy:(id)sender;

@end
