//
// MUProfilesController.h
//
// Copyright (c) 2007 3James Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MUPreferencesController : NSObject
{
  IBOutlet NSPanel *preferencesPanel;
  IBOutlet NSColorWell *globalTextColorWell;
  IBOutlet NSColorWell *globalBackgroundColorWell;
  IBOutlet NSColorWell *globalLinkColorWell;
  IBOutlet NSColorWell *globalVisitedLinkColorWell;
}

- (IBAction) changeFont;
- (void) colorPanelColorDidChange;
- (void) playSelectedSound: (id) sender;
- (void) showPreferencesPanel: (id) sender;

@end
