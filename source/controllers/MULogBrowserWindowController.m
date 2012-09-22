//
// MULogBrowserWindowController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MULogBrowserWindowController.h"
#import "MUTextLogDocument.h"

static MULogBrowserWindowController *sharedLogBrowserWindowController = nil;

@implementation MULogBrowserWindowController

+ (id) sharedLogBrowserWindowController
{
  if (!sharedLogBrowserWindowController)
    sharedLogBrowserWindowController = [[MULogBrowserWindowController alloc] init];
  
  return sharedLogBrowserWindowController;
}

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MULogBrowser"]))
    return nil;
  
  return self;
}

#pragma mark - NSWindowController overrides

- (void) setDocument: (NSDocument *) newDocument
{
  [super setDocument: newDocument];
  
  textView.string = [(MUTextLogDocument *) newDocument content];
  
  [self showWindow: self];
}

@end
