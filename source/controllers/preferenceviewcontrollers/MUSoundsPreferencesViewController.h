//
// MUSoundsPreferencesViewController.h
//
// Copyright (c) 2012 3James Software.
//

#import "MASPreferencesViewController.h"

@interface MUSoundsPreferencesViewController : NSViewController <MASPreferencesViewController>
{
  IBOutlet NSPopUpButton *soundsPopUpButton;
}

@property (readonly) NSArray *sounds;

- (IBAction) chooseSound: (id) sender;

@end
