//
// MUAcknowledgementsController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAcknowledgementsController.h"

@implementation MUAcknowledgementsController

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUAcknowledgements" owner: self]))
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

- (IBAction) openSparkleWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: MUSparkleURLString]];
}

@end
