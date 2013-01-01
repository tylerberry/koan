//
// MUConnectPanelController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectPanelController.h"

#import "MUPortFormatter.h"
#import "MUWorldRegistry.h"

@implementation MUConnectPanelController

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUConnectPanel" owner: self]))
    return nil;
  
  return self;
}

- (void) windowDidLoad
{
  MUPortFormatter *newConnectionPortFormatter = [[MUPortFormatter alloc] init];
  newConnectionPortField.formatter = newConnectionPortFormatter;
  
  newConnectionHostnameField.objectValue = nil;
  newConnectionPortField.objectValue = nil;
  newConnectionSaveWorldButton.state = NSOffState;
}

#pragma mark - Actions

- (IBAction) connectUsingPanelInformation: (id) sender
{
  MUWorld *world = [MUWorld worldWithHostname: newConnectionHostnameField.stringValue
                                         port: @(newConnectionPortField.intValue)];;
  
  if ([newConnectionSaveWorldButton state] == NSOnState)
  {
    MUWorldRegistry *registry = [MUWorldRegistry defaultRegistry];
    [[registry mutableArrayValueForKey: @"worlds"] insertObject: world
                                                        atIndex: registry.worlds.count];
  }
  
  [self.delegate openConnectionForWorld: world];
  [self.window close];
  
  newConnectionHostnameField.objectValue = nil;
  newConnectionPortField.objectValue = nil;
  newConnectionSaveWorldButton.state = NSOffState;
}

@end
