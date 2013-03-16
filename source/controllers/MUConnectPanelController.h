//
// MUConnectPanelController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"

@protocol MUConnectPanelControllerDelegate

@required
- (void) openConnectionForWorld: (MUWorld *) world;

@end

#pragma mark -

@interface MUConnectPanelController : NSWindowController
{
  IBOutlet NSTextField *newConnectionHostnameField;
  IBOutlet NSTextField *newConnectionPortField;
  IBOutlet NSButton *forceSSLButton;
  IBOutlet NSButton *newConnectionSaveWorldButton;
}

@property (weak, nonatomic) NSObject <MUConnectPanelControllerDelegate> *delegate;

- (IBAction) connectUsingPanelInformation: (id) sender;

@end
