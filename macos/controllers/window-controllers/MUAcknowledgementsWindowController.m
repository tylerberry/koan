//
// MUAcknowledgementsWindowController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAcknowledgementsWindowController.h"

@implementation MUAcknowledgementsWindowController
  
- (IBAction) openGrowlWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: MUGrowlURLString]];
}

- (IBAction) openOpenSSLWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: MUOpenSSLURLString]];
}

- (NSString *) windowNibName
{
  return @"MUAcknowledgementsWindow";
}

@end
