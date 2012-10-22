//
// MUProfileViewController.h
//
// Copyright (c) 2012 3James Software.
//

@class MUProfile;

@interface MUProfileViewController : NSViewController

@property (strong) MUProfile *profile;

// These properties proxy for the MUProfile's color values, allowing the underlying writable property to be edited while
// using the readonly "effective-" properties for display.
@property (unsafe_unretained) NSColor *editableEffectiveBackgroundColor;
@property (unsafe_unretained) NSColor *editableEffectiveLinkColor;
@property (unsafe_unretained) NSColor *editableEffectiveTextColor;

@property (weak) IBOutlet NSButton *toggleUseDefaultFontButton;

@property (weak) IBOutlet NSButton *toggleUseDefaultBackgroundColorButton;
@property (weak) IBOutlet NSButton *toggleUseDefaultLinkColorButton;
@property (weak) IBOutlet NSButton *toggleUseDefaultTextColorButton;

- (IBAction) toggleUseDefaultFont: (id) sender;

- (IBAction) toggleUseDefaultBackgroundColor: (id) sender;
- (IBAction) toggleUseDefaultLinkColor: (id) sender;
- (IBAction) toggleUseDefaultTextColor: (id) sender;

@end
