//
// MULogBrowserWindowController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MULogBrowserWindowController.h"
#import "MUTextLogDocument.h"

@implementation MULogBrowserWindowController

+ (instancetype) sharedLogBrowserWindowController
{
  static MULogBrowserWindowController *_sharedLogBrowserWindowController = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ _sharedLogBrowserWindowController = [[MULogBrowserWindowController alloc] init]; });
  
  return _sharedLogBrowserWindowController;
}

- (instancetype) init
{
  if (!(self = [super initWithWindowNibName: @"MULogBrowser" owner: self]))
    return nil;
  
  return self;
}

#pragma mark - NSWindowController overrides

- (void) setDocument: (NSDocument *) newDocument
{
  [super setDocument: newDocument];
  
  textView.string = ((MUTextLogDocument *) newDocument).content;
  
  [self showWindow: self];
}

@end
