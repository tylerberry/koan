//
// MUAcknowledgementsWindowController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAcknowledgementsWindowController.h"

@implementation MUAcknowledgementsWindowController

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUAcknowledgementsWindow" owner: self]))
    return nil;

  return self;
}
  
- (IBAction) openGrowlWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: MUGrowlURLString]];
}

- (IBAction) openOpenSSLWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: MUOpenSSLURLString]];
}

@end
