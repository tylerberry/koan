//
// MUProxyPreferencesViewController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MASPreferencesViewController.h"

@interface MUProxyPreferencesViewController : NSViewController <MASPreferencesViewController>
{
  IBOutlet NSMatrix *proxyRadioButtonMatrix;
}

@property (readonly) BOOL shouldEnableCustomProxyControls;

- (IBAction) proxyRadioButtonClicked: (id) sender;

@end
