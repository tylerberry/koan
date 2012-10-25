//
// MUProfileViewController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfileViewController.h"

#import "MUProfile.h"

@implementation MUProfileViewController

@dynamic editableEffectiveBackgroundColor, editableEffectiveLinkColor, editableEffectiveTextColor;

- (id) init
{
  if (!(self = [super initWithNibName: @"MUProfileView" bundle: nil]))
    return nil;
  
  [self addObserver: self forKeyPath: @"profile" options: NSKeyValueObservingOptionNew context: nil];
  
  return self;
}

- (void) awakeFromNib
{
  self.view.autoresizingMask = NSViewWidthSizable;
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
    MUProfile *oldProfile = changeDictionary[NSKeyValueChangeOldKey];
    MUProfile *newProfile = changeDictionary[NSKeyValueChangeNewKey];
    
    [oldProfile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
    [oldProfile removeObserver: self forKeyPath: @"effectiveLinkColor"];
    [oldProfile removeObserver: self forKeyPath: @"effectiveTextColor"];
    
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
    
    toggleUseDefaultFontButton.state = newProfile.font ? NSOffState : NSOnState;
    toggleUseDefaultBackgroundColorButton.state = newProfile.backgroundColor ? NSOffState : NSOnState;
    toggleUseDefaultLinkColorButton.state = newProfile.linkColor ? NSOffState : NSOnState;
    toggleUseDefaultTextColorButton.state = newProfile.textColor ? NSOffState : NSOnState;
    
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
  NSLog (@"Ping");
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

@end
