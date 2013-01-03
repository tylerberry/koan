//
// MULogBrowserWindowController.h
//
// Copyright (c) 2013 3James Software.
//

@interface MULogBrowserWindowController : NSWindowController
{
  IBOutlet NSTextView *textView;
}

+ (id) sharedLogBrowserWindowController;

@end
