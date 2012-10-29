//
//  MUConnectPanelController.h
//  Koan
//
//  Created by Tyler Berry on 10/28/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
  IBOutlet NSButton *newConnectionSaveWorldButton;
}

@property (weak, nonatomic) NSObject <MUConnectPanelControllerDelegate> *delegate;

- (IBAction) connectUsingPanelInformation: (id) sender;

@end
