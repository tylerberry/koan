//
// MUProxySettingsController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUProxySettings;

@interface MUProxySettingsController : NSWindowController
{
  IBOutlet NSTextField *hostnameField;
  IBOutlet NSTextField *portField;
}

- (MUProxySettings *) proxySettings;

@end
