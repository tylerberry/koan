//
// MUSoundsPreferencesViewController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MASPreferencesViewController.h"

@interface MUSoundsPreferencesViewController : NSViewController <MASPreferencesViewController>
{
  IBOutlet NSPopUpButton *soundsPopUpButton;
}

- (IBAction) playCurrentSound: (id) sender;

@end
