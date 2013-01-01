//
// MUProfileViewController.h
//
// Copyright (c) 2013 3James Software.
//

@class MUProfile;

@interface MUProfileViewController : NSViewController
{
  IBOutlet NSButton *toggleUseDefaultFontButton;
  
  IBOutlet NSButton *toggleUseDefaultBackgroundColorButton;
  IBOutlet NSButton *toggleUseDefaultLinkColorButton;
  IBOutlet NSButton *toggleUseDefaultTextColorButton;
}

@property (strong) MUProfile *profile;

@property (weak) IBOutlet NSView *firstView;
@property (weak) IBOutlet NSView *lastView;

// These properties proxy for the MUProfile's color values, allowing the underlying writable property to be edited while
// using the readonly "effective-" properties for display.

@property (unsafe_unretained) NSColor *editableEffectiveBackgroundColor;
@property (unsafe_unretained) NSColor *editableEffectiveLinkColor;
@property (unsafe_unretained) NSColor *editableEffectiveTextColor;

- (IBAction) toggleUseDefaultFont: (id) sender;

- (IBAction) toggleUseDefaultBackgroundColor: (id) sender;
- (IBAction) toggleUseDefaultLinkColor: (id) sender;
- (IBAction) toggleUseDefaultTextColor: (id) sender;

@end
