//
// MUFontsAndColorsPreferencesViewController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MASPreferencesViewController.h"

@interface MUFontsAndColorsPreferencesViewController : NSViewController <MASPreferencesViewController>
{
  IBOutlet NSMatrix *fontRadioButtonMatrix;
}

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) fontRadioButtonClicked: (id) sender;

@end
