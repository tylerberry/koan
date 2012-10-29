//
// MUConnectPanelController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUConnectPanelController.h"

#import "MUPortFormatter.h"
#import "MUWorldRegistry.h"

@interface MUConnectPanelController ()

@end

@implementation MUConnectPanelController

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUConnectPanel" owner: self]))
    return nil;
  
  return self;
}

- (void) windowDidLoad
{
  [super windowDidLoad];
  
  newConnectionHostnameField.objectValue = nil;
  newConnectionPortField.objectValue = nil;
  newConnectionSaveWorldButton.state = NSOffState;
  
  MUPortFormatter *newConnectionPortFormatter = [[MUPortFormatter alloc] init];
  newConnectionPortField.formatter = newConnectionPortFormatter;
}

#pragma mark - Actions

- (IBAction) connectUsingPanelInformation: (id) sender
{
  MUWorld *world = [MUWorld worldWithHostname: newConnectionHostnameField.stringValue
                                         port: @(newConnectionPortField.intValue)];;
  
  if ([newConnectionSaveWorldButton state] == NSOnState)
  	[[MUWorldRegistry defaultRegistry] insertObject: world
                                    inWorldsAtIndex: [MUWorldRegistry defaultRegistry].worlds.count];
  
  [self.delegate openConnectionForWorld: world];
  [self.window close];
  
  newConnectionHostnameField.objectValue = nil;
  newConnectionPortField.objectValue = nil;
  newConnectionSaveWorldButton.state = NSOffState;
}

@end
