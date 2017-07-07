//
// MUConnectPanelController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectPanelController.h"

#import "MUWorldRegistry.h"

@interface MUConnectPanelController ()

- (void) _resetInterface;

@end

#pragma mark -

@implementation MUConnectPanelController

- (instancetype) init
{
  if (!(self = [super initWithWindowNibName: @"MUConnectPanel" owner: self]))
    return nil;
  
  return self;
}

- (void) windowDidLoad
{
  [self _resetInterface];
}

#pragma mark - Actions

- (IBAction) connectUsingPanelInformation: (id) sender
{
  NSString *worldString = newConnectionHostnameField.stringValue;
  NSString *trimmedString = [worldString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  MUWorld *world = [MUWorld worldWithHostname: trimmedString
                                         port: @(newConnectionPortField.intValue)
                                     forceTLS: (forceSSLButton.state == NSOnState)];
  
  if (newConnectionSaveWorldButton.state == NSOnState)
  {
    MUWorldRegistry *registry = [MUWorldRegistry defaultRegistry];
    [[registry mutableArrayValueForKey: @"worlds"] insertObject: world
                                                        atIndex: registry.worlds.count];
  }
  
  [self.delegate openConnectionForWorld: world];
  [self.window close];
  
  [self _resetInterface];
}

#pragma mark - Private methods

- (void) _resetInterface
{
  newConnectionHostnameField.objectValue = nil;
  newConnectionPortField.objectValue = nil;
  forceSSLButton.state = NSOffState;
  newConnectionSaveWorldButton.state = NSOffState;

  [self.window makeFirstResponder: newConnectionHostnameField];
}

@end
