//
// MUProfilesWindowController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUPreferencesController : NSObject
{
  IBOutlet NSWindow *preferencesWindow;

  IBOutlet NSColorWell *globalTextColorWell;
  IBOutlet NSColorWell *globalBackgroundColorWell;
  IBOutlet NSColorWell *globalLinkColorWell;
  IBOutlet NSColorWell *globalVisitedLinkColorWell;
}

- (void) colorPanelColorDidChange;
- (void) playSelectedSound: (id) sender;
- (void) showPreferencesWindow: (id) sender;

// Responder chain methods

- (IBAction) changeFont: (id) sender;

@end
