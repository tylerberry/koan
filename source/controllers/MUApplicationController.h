//
// MUApplicationController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectPanelController.h"
#import "MUConnectionWindowController.h"
#import "MUProfilesWindowController.h"

@class MUPreferencesController;

@interface MUApplicationController : NSObject <NSApplicationDelegate, MUConnectPanelControllerDelegate, MUConnectionWindowControllerDelegate, MUProfilesWindowControllerDelegate>
{
  IBOutlet NSMenu *openConnectionMenu;
}

// User defaults key path string methods

+ (NSString *) keyPathForBackgroundColor;
+ (NSString *) keyPathForFont;
+ (NSString *) keyPathForLinkColor;
+ (NSString *) keyPathForSystemTextColor;
+ (NSString *) keyPathForTextColor;

+ (NSString *) keyPathForANSIBlackColor;
+ (NSString *) keyPathForANSIRedColor;
+ (NSString *) keyPathForANSIGreenColor;
+ (NSString *) keyPathForANSIYellowColor;
+ (NSString *) keyPathForANSIBlueColor;
+ (NSString *) keyPathForANSIMagentaColor;
+ (NSString *) keyPathForANSICyanColor;
+ (NSString *) keyPathForANSIWhiteColor;

+ (NSString *) keyPathForANSIBrightBlackColor;
+ (NSString *) keyPathForANSIBrightRedColor;
+ (NSString *) keyPathForANSIBrightGreenColor;
+ (NSString *) keyPathForANSIBrightYellowColor;
+ (NSString *) keyPathForANSIBrightBlueColor;
+ (NSString *) keyPathForANSIBrightMagentaColor;
+ (NSString *) keyPathForANSIBrightCyanColor;
+ (NSString *) keyPathForANSIBrightWhiteColor;

+ (NSString *) keyPathForDisplayBrightAsBold;

+ (NSString *) keyPathForSoundChoice;
+ (NSString *) keyPathForSoundVolume;

- (IBAction) chooseNewFont: (id) sender;
- (IBAction) connectToURL: (NSURL *) url;

- (IBAction) openBugsWebPage: (id) sender;
- (IBAction) showAboutPanel: (id) sender;
- (IBAction) showAcknowledgementsWindow: (id) sender;
- (IBAction) showConnectPanel: (id) sender;
- (IBAction) showPreferencesWindow: (id) sender;
- (IBAction) showProfilesWindow: (id) sender;

@end
