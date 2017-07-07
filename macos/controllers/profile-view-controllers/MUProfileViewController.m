//
// MUProfileViewController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProfileViewController.h"

#import "MUProfile.h"

@interface MUProfileViewController ()

- (void) _updateButtonStates;

@end

#pragma mark -

@implementation MUProfileViewController

@dynamic editableEffectiveBackgroundColor, editableEffectiveLinkColor, editableEffectiveTextColor;

- (instancetype) init
{
  if (!(self = [super initWithNibName: @"MUEditProfileView" bundle: nil]))
    return nil;
  
  [self addObserver: self
         forKeyPath: @"profile"
            options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
            context: nil];
  
  return self;
}

- (void) awakeFromNib
{
  self.view.autoresizingMask = NSViewWidthSizable;
  [self _updateButtonStates];
}

- (void) dealloc
{
  [self removeObserver: self forKeyPath: @"profile"];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == self && [keyPath isEqualToString: @"profile"])
  {
    id oldValue = changeDictionary[NSKeyValueChangeOldKey];
    MUProfile *oldProfile;
    
    if ([oldValue isKindOfClass: [MUProfile class]])
      oldProfile = (MUProfile *) oldValue;
    else
      oldProfile = nil;
    
    id newValue = changeDictionary[NSKeyValueChangeNewKey];

    MUProfile *newProfile = [newValue isKindOfClass: [MUProfile class]] ? (MUProfile *) newValue : nil;
    
    if (oldProfile)
    {
      [oldProfile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
      [oldProfile removeObserver: self forKeyPath: @"effectiveLinkColor"];
      [oldProfile removeObserver: self forKeyPath: @"effectiveTextColor"];
    }
    
    if (newProfile)
    {
      [newProfile addObserver: self
                   forKeyPath: @"effectiveBackgroundColor"
                      options: NSKeyValueObservingOptionNew
                      context: nil];
      [newProfile addObserver: self
                   forKeyPath: @"effectiveLinkColor"
                      options: NSKeyValueObservingOptionNew
                      context: nil];
      [newProfile addObserver: self
                   forKeyPath: @"effectiveTextColor"
                      options: NSKeyValueObservingOptionNew
                      context: nil];
    
      [self _updateButtonStates];
    }
    else
    {
      NSLog (@"Error: MUProfileViewController.representedObject got set to something that isn't an MUProfile.");
      return;
    }
    
    [self willChangeValueForKey: @"editableEffectiveBackgroundColor"];
    [self didChangeValueForKey: @"editableEffectiveBackgroundColor"];
    
    [self willChangeValueForKey: @"editableEffectiveLinkColor"];
    [self didChangeValueForKey: @"editableEffectiveLinkColor"];
    
    [self willChangeValueForKey: @"editableEffectiveTextColor"];
    [self didChangeValueForKey: @"editableEffectiveTextColor"];
    
    return;
  }
  else if (object == self.profile)
  {
    if ([keyPath isEqualToString: @"effectiveBackgroundColor"])
    {
      [self willChangeValueForKey: @"editableEffectiveBackgroundColor"];
      [self didChangeValueForKey: @"editableEffectiveBackgroundColor"];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveLinkColor"])
    {
      [self willChangeValueForKey: @"editableEffectiveLinkColor"];
      [self didChangeValueForKey: @"editableEffectiveLinkColor"];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveTextColor"])
    {
      [self willChangeValueForKey: @"editableEffectiveTextColor"];
      [self didChangeValueForKey: @"editableEffectiveTextColor"];
      return;
    }
  }
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

#pragma mark - Properties

- (NSColor *) editableEffectiveBackgroundColor
{
  return self.profile.effectiveBackgroundColor;
}

- (void) setEditableEffectiveBackgroundColor: (NSColor *) newBackgroundColor
{
  self.profile.backgroundColor = newBackgroundColor;
}

- (NSColor *) editableEffectiveLinkColor
{
  return self.profile.effectiveLinkColor;
}

- (void) setEditableEffectiveLinkColor: (NSColor *) newLinkColor
{
  self.profile.linkColor = newLinkColor;
}

- (NSColor *) editableEffectiveTextColor
{
  return self.profile.effectiveTextColor;
}

- (void) setEditableEffectiveTextColor: (NSColor *) newTextColor
{
  self.profile.textColor = newTextColor;
}

- (void) setNextResponder: (NSResponder *) responder
{
  [super setNextResponder: responder];
}

#pragma mark - Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSFont *font = self.profile.font;
  
  if (font == nil)
  {
    NSLog (@"Warning: should not be showing font panel when default font is being used.");
    font = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  }
  
  [[NSFontManager sharedFontManager] setSelectedFont: font isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) toggleUseDefaultFont: (id) sender
{
  NSButton *senderButton = (NSButton *) sender;
  
  if (senderButton.state == NSOnState)
    self.profile.font = nil;
  else
    self.profile.font = self.profile.effectiveFont;
}

- (IBAction) toggleUseDefaultBackgroundColor: (id) sender
{
  NSButton *senderButton = (NSButton *) sender;
  
  if (senderButton.state == NSOnState)
    self.profile.backgroundColor = nil;
  else
    self.profile.backgroundColor = self.profile.effectiveBackgroundColor;
}

- (IBAction) toggleUseDefaultLinkColor: (id) sender
{
  NSButton *senderButton = (NSButton *) sender;
  
  if (senderButton.state == NSOnState)
    self.profile.linkColor = nil;
  else
    self.profile.linkColor = self.profile.effectiveLinkColor;
}

- (IBAction) toggleUseDefaultTextColor: (id) sender
{
  NSButton *senderButton = (NSButton *) sender;
  
  if (senderButton.state == NSOnState)
    self.profile.textColor = nil;
  else
    self.profile.textColor = self.profile.effectiveTextColor;
}

#pragma mark - Private methods

- (void) _updateButtonStates
{
  if (self.profile)
  {
    toggleUseDefaultFontButton.state = self.profile.font ? NSOffState : NSOnState;
    toggleUseDefaultBackgroundColorButton.state = self.profile.backgroundColor ? NSOffState : NSOnState;
    toggleUseDefaultLinkColorButton.state = self.profile.linkColor ? NSOffState : NSOnState;
    toggleUseDefaultTextColorButton.state = self.profile.textColor ? NSOffState : NSOnState;
  }
}

@end
