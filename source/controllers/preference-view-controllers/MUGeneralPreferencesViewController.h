//
// MUGeneralPreferencesViewController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MASPreferencesViewController.h"

@interface MUGeneralPreferencesViewController : NSViewController <MASPreferencesViewController>
{
  IBOutlet NSPopUpButton *telnetHandlerPopUpButton;
}

- (IBAction) chooseTelnetHandler: (id) sender;

@end
