//
// MUFontsAndColorsPreferencesViewController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFontsAndColorsPreferencesViewController.h"

@implementation MUFontsAndColorsPreferencesViewController

@synthesize identifier = _identifier;
@synthesize toolbarItemImage = _toolbarItemImage;
@synthesize toolbarItemLabel = _toolbarItemLabel;

- (id) init
{
  if (!(self = [super initWithNibName: @"MUFontsAndColorsPreferencesView" bundle: nil]))
    return nil;
  
  _identifier = @"fontsandcolors";
  _toolbarItemImage = [NSImage imageNamed: @"FontsAndColors"];
  _toolbarItemLabel = _(MULPreferencesFontsAndColors);
  
  return self;
}

- (void) awakeFromNib
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSNumber *defaultFontChangeBehaviorNumber = [userDefaults objectForKey: MUPDefaultFontChangeBehavior];
  
  [fontRadioButtonMatrix selectCellWithTag: defaultFontChangeBehaviorNumber.integerValue];
}

#pragma mark - IBActions

- (IBAction) chooseNewFont: (id) sender
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSFont *defaultFont = [NSUnarchiver unarchiveObjectWithData: [userDefaults dataForKey: MUPFont]];
  
  if (defaultFont == nil)
  {
    NSLog (@"Warning: default font is nil.");
    defaultFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  }
  
  [[NSFontManager sharedFontManager] setSelectedFont: defaultFont isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) fontRadioButtonClicked: (id) sender
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [userDefaults setInteger: fontRadioButtonMatrix.selectedTag forKey: MUPDefaultFontChangeBehavior];
}

#pragma mark - Responder chain actions

- (IBAction) changeProfileFont: (id) sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = fontManager.selectedFont;
  
  if (selectedFont == nil)
  {
    NSLog (@"Warning: font panel returned nil selected font.");
    selectedFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  }
  
  NSFont *panelFont = [fontManager convertFont: selectedFont];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject: [NSArchiver archivedDataWithRootObject: panelFont] forKey: MUPFont];
}

@end
