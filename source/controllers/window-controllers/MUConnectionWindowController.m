//
// MUConnectionWindowController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectionWindowController.h"

#import "MUApplicationController.h"
#import "MUGrowlService.h"
#import "MUHistoryRing.h"
#import "MULayoutManager.h"

#import "NSFont+Traits.h"

#import <objc/objc-runtime.h>
#include <tgmath.h>

enum MUSearchDirections
{
  MUBackwardSearch,
  MUForwardSearch
};

enum MUTextDisplayModes
{
  MUNormalTextDisplayMode,
  MUPromptTextDisplayMode,
  MUEchoedTextDisplayMode
};

@interface MUConnectionWindowController ()

- (void) _clearPrompt;
- (void) _didEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
- (void) _displayAttributedString: (NSAttributedString *) attributedString
                  textDisplayMode: (enum MUTextDisplayModes) textDisplayMode;
- (void) _displaySystemMessage: (NSString *) string;
- (void) _echoString: (NSString *) string;
- (void) _endCompletion;
- (void) _postConnectionWindowControllerDidReceiveTextNotification;
- (void) _postConnectionWindowControllerWillCloseNotification;
- (void) _prepareDelayedReportWindowSizeToServer;
- (void) _scrollDisplayViewToBottom;
- (void) _setTextViewsNeedDisplay: (NSNotification *) notification;
- (BOOL) _shouldScrollDisplayViewToBottom;
- (NSString *) _splitViewAutosaveName;
- (void) _startDisplayingTimeConnected;
- (void) _stopDisplayingTimeConnected;
- (void) _tabCompleteWithDirection: (enum MUSearchDirections) direction;
- (void) _triggerDelayedReportWindowSizeToServer: (NSTimer *) timer;
- (void) _updateANSIColorsForColor: (enum MUAbstractANSIColors) color;
- (void) _updateBackgroundColor;
- (void) _updateFonts;
- (void) _updateLinkTextColor;
- (void) _updateSystemTextColor;
- (void) _updateTextColor;
- (void) _updateTimeConnectedField: (NSTimer *) timer;
- (void) _willEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
- (CGFloat) _windowHeightForCandidateHeight: (CGFloat) candidateHeight;
- (CGFloat) _windowWidthForCandidateWidth: (CGFloat) candidateWidth;

@end

#pragma mark -

@implementation MUConnectionWindowController
{
  BOOL _currentlySearching;

  BOOL _shouldScrollToBottomAfterFullScreenTransition;
  BOOL _shouldScrollToBottomAfterResize;

  MUHistoryRing *_historyRing;

  NSAttributedString *_currentPrompt;
  NSRange _currentTextRangeWithoutPrompt;

  NSTimer *_timeConnectedFieldTimer;
  NSTimer *_windowSizeNotificationTimer;
}

- (instancetype) initWithProfile: (MUProfile *) newProfile
{
  if (!(self = [super initWithWindowNibName: @"MUConnectionWindow" owner: self]))
    return nil;
  
  _connection = [[MUMUDConnection alloc] initWithProfile: newProfile delegate: self];
  
  _historyRing = [MUHistoryRing historyRing];
  
  _currentPrompt = nil;
  _currentTextRangeWithoutPrompt = NSMakeRange (0, 0);
  
  _currentlySearching = NO;
  _windowSizeNotificationTimer = nil;
  
  return self;
}

- (instancetype) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
{
  return [self initWithProfile: [MUProfile profileWithWorld: newWorld player: newPlayer]];
}

- (instancetype) initWithWorld: (MUWorld *) newWorld
{
  return [self initWithWorld: newWorld player: nil];
}

- (void) awakeFromNib
{
  // Replace the layout manager with our custom one that doesn't ignore whitespace for underlining.
  
  [receivedTextView.textContainer replaceLayoutManager: [[MULayoutManager alloc] init]];
  receivedTextView.layoutManager.allowsNonContiguousLayout = YES;

  // Disable text substitution options on the input text view.

  [inputTextView setAutomaticDashSubstitutionEnabled: NO];
  [inputTextView setAutomaticDataDetectionEnabled: NO];
  [inputTextView setAutomaticLinkDetectionEnabled: NO];
  [inputTextView setAutomaticQuoteSubstitutionEnabled: NO];
  [inputTextView setAutomaticTextReplacementEnabled: NO];

  // Set the initial link text color.
  
  [self _updateLinkTextColor];
  
  // Restore window and split view title, size, and position.
  
  self.window.title = self.connection.profile.windowTitle;

  self.window.frameAutosaveName = self.connection.profile.uniqueIdentifier;
  [self.window setFrameUsingName: self.connection.profile.uniqueIdentifier];

  splitView.autosaveName = [self _splitViewAutosaveName];
  [splitView adjustSubviews];

  // Ratchet the window down to respect column and line size.

  [self.window setFrame: NSMakeRect (self.window.frame.origin.x,
                                     self.window.frame.origin.y,
                                     [self _windowWidthForCandidateWidth: self.window.frame.size.width],
                                     [self _windowHeightForCandidateHeight: self.window.frame.size.height])
                display: YES];

  NSLog (@"%g, %g", ((NSView *) self.window.contentView).frame.size.width, ((NSView *) self.window.contentView).frame.size.height);
  NSLog (@"splitView height: frame %g bounds %g", splitView.frame.size.height, splitView.bounds.size.height);
  NSLog (@"receivedTextView height: frame %g bounds %g", receivedTextView.frame.size.height, receivedTextView.bounds.size.height);
  NSLog (@"inputTextView height: frame %g bounds %g", inputTextView.frame.size.height, inputTextView.bounds.size.height);

  NSLog (@"receivedTextView width: frame %g bounds %g", receivedTextView.frame.size.width, receivedTextView.bounds.size.width);
  NSLog (@"inputTextView width: frame %g bounds %g", inputTextView.frame.size.width, inputTextView.bounds.size.width);

  // Bindings and notifications.
  
  [receivedTextView bind: @"backgroundColor"
                toObject: self.connection.profile
             withKeyPath: @"effectiveBackgroundColor"
                 options: nil];
  
  [inputTextView bind: @"font"
         toObject: self.connection.profile
      withKeyPath: @"effectiveFont"
          options: nil];
  [inputTextView bind: @"textColor"
         toObject: self.connection.profile
      withKeyPath: @"effectiveTextColor"
          options: nil];
  [inputTextView bind: @"insertionPointColor"
         toObject: self.connection.profile
      withKeyPath: @"effectiveTextColor"
          options: nil];
  [inputTextView bind: @"backgroundColor"
         toObject: self.connection.profile
      withKeyPath: @"effectiveBackgroundColor"
          options: nil];
  
  [self.connection.profile addObserver: self
                            forKeyPath: @"effectiveBackgroundColor"
                               options: NSKeyValueObservingOptionNew
                               context: nil];
  [self.connection.profile addObserver: self
                            forKeyPath: @"effectiveFont"
                               options: NSKeyValueObservingOptionNew
                               context: nil];
  [self.connection.profile addObserver: self
                            forKeyPath: @"effectiveLinkColor"
                               options: NSKeyValueObservingOptionNew
                               context: nil];
  [self.connection.profile addObserver: self
                            forKeyPath: @"effectiveSystemTextColor"
                               options: NSKeyValueObservingOptionNew
                               context: nil];
  [self.connection.profile addObserver: self
                            forKeyPath: @"effectiveTextColor"
                               options: NSKeyValueObservingOptionNew
                               context: nil];
  
  NSUserDefaultsController *sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBlackColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIRedColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIGreenColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIYellowColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBlueColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIMagentaColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSICyanColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIWhiteColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightBlackColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightRedColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightGreenColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightYellowColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightBlueColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightMagentaColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightCyanColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForANSIBrightWhiteColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [MUApplicationController keyPathForDisplayBrightAsBold]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
}

- (void) dealloc
{
  [self.connection close];
  
  [self.connection.profile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
  [self.connection.profile removeObserver: self forKeyPath: @"effectiveFont"];
  [self.connection.profile removeObserver: self forKeyPath: @"effectiveLinkColor"];
  [self.connection.profile removeObserver: self forKeyPath: @"effectiveSystemTextColor"];
  [self.connection.profile removeObserver: self forKeyPath: @"effectiveTextColor"];
  
  NSUserDefaultsController *sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBlackColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIRedColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIGreenColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIYellowColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBlueColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIMagentaColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSICyanColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIWhiteColor]];
  
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightBlackColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightRedColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightGreenColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightYellowColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightBlueColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightMagentaColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightCyanColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForANSIBrightWhiteColor]];
  
  [sharedDefaultsController removeObserver: self forKeyPath: [MUApplicationController keyPathForDisplayBrightAsBold]];
  
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  [[NSNotificationCenter defaultCenter] removeObserver: nil name: nil object: self];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == self.connection.profile)
  {
    if ([keyPath isEqualToString: @"effectiveBackgroundColor"])
    {
      [self _updateBackgroundColor];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveFont"])
    {
      [self _updateFonts];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveLinkColor"])
    {
      [self _updateLinkTextColor];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveSystemTextColor"])
    {
      [self _updateSystemTextColor];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveTextColor"])
    {
      [self _updateTextColor];
      return;
    }
  }
  else if (object == [NSUserDefaultsController sharedUserDefaultsController])
  {
    if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBlackColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBlackColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIRedColor]])
    {
      [self _updateANSIColorsForColor: MUANSIRedColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIGreenColor]])
    {
      [self _updateANSIColorsForColor: MUANSIGreenColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIYellowColor]])
    {
      [self _updateANSIColorsForColor: MUANSIYellowColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBlueColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBlueColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIMagentaColor]])
    {
      [self _updateANSIColorsForColor: MUANSIMagentaColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSICyanColor]])
    {
      [self _updateANSIColorsForColor: MUANSICyanColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIWhiteColor]])
    {
      [self _updateANSIColorsForColor: MUANSIWhiteColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightBlackColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightBlackColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightRedColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightRedColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightGreenColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightGreenColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightYellowColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightYellowColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightBlueColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightBlueColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightMagentaColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightMagentaColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightCyanColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightCyanColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForANSIBrightWhiteColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightWhiteColor];
      return;
    }
    else if ([keyPath isEqualToString: [MUApplicationController keyPathForDisplayBrightAsBold]])
    {
      [self _updateFonts];
      return;
    }
  }
  [super observeValueForKeyPath: keyPath ofObject: object change: changeDictionary context: context];
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
  SEL menuItemAction = [menuItem action];
  
  if (menuItemAction == @selector (connectOrDisconnect:))
  {
    if (self.connection.isConnectedOrConnecting)
      menuItem.title = _(MULDisconnect);
    else
      menuItem.title = _(MULConnect);
    return YES;
  }
  
  return YES;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
  SEL toolbarItemAction = toolbarItem.action;
  
  if (toolbarItemAction == @selector (goToWorldURL:))
  {
    NSString *url = self.connection.profile.world.url;
    
    return (url && ![url isEqualToString: @""]);
  }
  
  return NO;
}
  
#pragma mark - Accessors

- (void) setDelegate: (id) newDelegate
{
  if (_delegate == newDelegate)
    return;
  
  [[NSNotificationCenter defaultCenter] removeObserver: _delegate name: nil object: self];
  
  if ([newDelegate respondsToSelector: @selector (connectionWindowControllerWillClose:)])
  {
    [[NSNotificationCenter defaultCenter] addObserver: newDelegate
                                             selector: @selector (connectionWindowControllerWillClose:)
                                                 name: MUConnectionWindowControllerWillCloseNotification
                                               object: self];
  }
  
  if ([newDelegate respondsToSelector: @selector (connectionWindowControllerDidReceiveText:)])
  {
    [[NSNotificationCenter defaultCenter] addObserver: newDelegate
                                             selector: @selector (connectionWindowControllerDidReceiveText:)
                                                 name: MUConnectionWindowControllerDidReceiveTextNotification
                                               object: self];
  }
  
  _delegate = newDelegate;
}

#pragma mark - Actions

- (void) confirmClose: (SEL) callback
{
  [self.window makeKeyAndOrderFront: nil];
  
  NSBeginAlertSheet ([NSString stringWithFormat: _(MULConfirmCloseTitle), self.connection.profile.windowTitle],
                     _(MULOK),
                     _(MULCancel),
                     nil,
                     self.window,
                     self,
                     @selector (_willEndCloseSheet:returnCode:contextInfo:),
                     @selector (_didEndCloseSheet:returnCode:contextInfo:),
                     (void *) callback,
                     _(MULConfirmCloseMessage),
                     self.connection.profile.hostname);
}

- (IBAction) clearWindow: (id) sender
{
  receivedTextView.string = @"";
}

- (IBAction) connect: (id) sender
{
  [self.connection open];
}

- (IBAction) connectOrDisconnect: (id) sender
{
  if (self.connection.isConnectedOrConnecting)
    [self disconnect: sender];
  else
    [self connect: sender];
}

- (IBAction) disconnect: (id) sender
{
  [self.connection close];
}

- (IBAction) goToWorldURL: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: self.connection.profile.world.url]];
}

- (IBAction) sendInputText: (id) sender
{
  [self.connection writeLine: inputTextView.string];
  
  if (!self.connection.state.serverWillEcho)
  {
    [_historyRing saveString: inputTextView.string];
  
    if (_currentPrompt)
    {
      [self _echoString: [NSString stringWithFormat: @"%@\n", inputTextView.string]];
      _currentPrompt = nil;
    }
  }
  else if (_currentPrompt)
  {
    [self _echoString: @"\n"];
    _currentPrompt = nil;
  }
  
  inputTextView.string = @"";
  inputTextView.font = self.connection.profile.effectiveFont; // Sending non-ASCII text can screw up the font. Resetting it
                                                          // here makes sure we don't suddenly have a weird proportional
                                                          // font out of nowhere.
  [self.window makeFirstResponder: inputTextView];
}

- (IBAction) nextCommand: (id) sender
{
  [_historyRing updateString: inputTextView.string];
  inputTextView.string = [_historyRing nextString];
}

- (IBAction) previousCommand: (id) sender
{
  [_historyRing updateString: inputTextView.string];
  inputTextView.string = [_historyRing previousString];
}

#pragma mark - Responder chain methods

- (void) changeProfileFont: (id) sender
{
  BOOL changeUserDefaultsFont = NO;
  
  if (self.connection.profile.font == nil)
  {
    // If profile.font is nil, then we don't handle this message.
    // TODO: Should we? Should this change the application default?
    return;
  }
  
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = fontManager.selectedFont;
  
  if (selectedFont == nil)
    selectedFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  NSFont *convertedFont = [fontManager convertFont: selectedFont];
  
  self.connection.profile.font = convertedFont;
}

- (void) makeProfileTextLarger: (id) sender
{
  NSFont *currentFont = self.connection.profile.font;
  
  if (currentFont == nil)
  {
    // If profile.font is nil, then we don't handle this message.
    // TODO: Should we? Should this change the application default?
    return;
  }
  
  CGFloat largerFontSize = floor (currentFont.pointSize) + 1.0;
  
  NSFont *largerFont = [[NSFontManager sharedFontManager] convertFont: currentFont toSize: largerFontSize];
  
  self.connection.profile.font = largerFont;
  [[NSFontManager sharedFontManager] setSelectedFont: largerFont isMultiple: NO];
}

- (void) makeProfileTextSmaller: (id) sender
{
  NSFont *currentFont = self.connection.profile.font;
  
  if (currentFont == nil)
  {
    // If profile.font is nil, then we don't handle this message.
    // TODO: Should we? Should this change the application default?
    return;
  }
  
  CGFloat smallerFontSize = floor (currentFont.pointSize) - 1.0;
  
  if (smallerFontSize < 1.0)
  {
    NSBeep ();
    return;
  }
    
  NSFont *smallerFont = [[NSFontManager sharedFontManager] convertFont: currentFont toSize: smallerFontSize];
  
  self.connection.profile.font = smallerFont;
  [[NSFontManager sharedFontManager] setSelectedFont: smallerFont isMultiple: NO];
}

#pragma mark - Filter delegate methods

- (void) setInputViewString: (NSString *) string
{
  inputTextView.string = string;
}

#pragma mark - MUMUDConnectionDelegate protocol

- (void) displayAttributedString: (NSAttributedString *) attributedString
{
  if (attributedString && attributedString.length > 0)
    [self _displayAttributedString: attributedString textDisplayMode: MUNormalTextDisplayMode];
}

- (void) displayAttributedStringAsPrompt: (NSAttributedString *) attributedString
{
  if (attributedString && attributedString.length > 0)
    [self _displayAttributedString: attributedString textDisplayMode: MUPromptTextDisplayMode];
  else
    [self _clearPrompt];
}

- (void) reportWindowSizeToServer
{
  [self.connection sendNumberOfWindowLines: receivedTextView.numberOfLines
                                   columns: receivedTextView.numberOfColumns];
}

- (void) MUDConnectionDidConnect: (NSNotification *) notification
{
  [self _displaySystemMessage: _(MULConnectionOpen)];
  [MUGrowlService connectionOpenedForTitle: self.connection.profile.windowTitle];

  [self _startDisplayingTimeConnected];

  if (self.connection.profile.hasLoginInformation)
    [_connection writeLine: self.connection.profile.loginString];
}

- (void) MUDConnectionIsConnecting: (NSNotification *) notification
{
  [self _displaySystemMessage: _(MULConnectionOpening)];
}

- (void) MUDConnectionWasClosedByClient: (NSNotification *) notification
{
  [self _stopDisplayingTimeConnected];
  if (_currentPrompt)
  {
    [self _echoString: @"\n"];
    [self _clearPrompt];
  }
  [self _echoString: @"\n"];
  [self _displaySystemMessage: _(MULConnectionClosed)];
  [MUGrowlService connectionClosedForTitle: self.connection.profile.windowTitle];
}

- (void) MUDConnectionWasClosedByServer: (NSNotification *) notification
{
  [self _stopDisplayingTimeConnected];
  if (_currentPrompt)
  {
    [self _echoString: @"\n"];
    [self _clearPrompt];
  }
  [self _echoString: @"\n"];
  [self _displaySystemMessage: _(MULConnectionClosedByServer)];
  [MUGrowlService connectionClosedByServerForTitle: self.connection.profile.windowTitle];
}

- (void) MUDConnectionWasClosedWithError: (NSNotification *) notification
{
  [self _stopDisplayingTimeConnected];
  if (_currentPrompt)
  {
    [self _echoString: @"\n"];
    [self _clearPrompt];
  }
  [self _echoString: @"\n"];

  NSError *error = notification.userInfo[MUMUDConnectionErrorKey];

  [MUGrowlService connectionClosedByErrorForTitle: self.connection.profile.windowTitle error: error];

  if (error)
  {
    [self _displaySystemMessage: [NSString stringWithFormat: _(MULConnectionClosedByError), error.localizedDescription]];
  }
  else
  {
    [self _displaySystemMessage: [NSString stringWithFormat: _(MULConnectionClosedByError), _(MULConnectionNoErrorAvailable)]];
  }
}

#pragma mark - MUTextViewPasteDelegate protocol

- (BOOL) textView: (MUTextView *) textView insertText: (id) string
{
  if (textView == receivedTextView)
  {
    [inputTextView insertText: string];
    [self.window makeFirstResponder: inputTextView];
    return YES;
  }
  else if (textView == inputTextView)
  {
    [self _endCompletion];
    return NO;
  }
  return NO;
}

- (BOOL) textView: (MUTextView *) textView pasteAsPlainText: (id) originalSender
{
  if (textView == receivedTextView)
  {
    [inputTextView pasteAsPlainText: originalSender];
    [self.window makeFirstResponder: inputTextView];
    return YES;
  }
  else if (textView == inputTextView)
  {
    [self _endCompletion];
    return NO;
  }
  return NO;
}

- (BOOL) textView: (MUTextView *) textView performFindPanelAction: (id) originalSender
{
  if (textView == inputTextView)
  {
    [receivedTextView performFindPanelAction: originalSender];
    return YES;
  }
  return NO;
}

#pragma mark - NSSplitViewDelegate protocol

- (BOOL) splitView: (NSSplitView *) view shouldAdjustSizeOfSubview: (NSView *) subview
{
  // This causes the input portion of the view to remain constant size if possible when the window is resizing.

  return subview != inputTextView.enclosingScrollView;
}

- (CGFloat)  splitView: (NSSplitView *) view
constrainSplitPosition: (CGFloat) proposedPosition
           ofSubviewAt: (NSInteger) dividerIndex
{
  CGFloat position = proposedPosition;

  if (view == splitView && dividerIndex == 0)
  {
    NSScrollView *scrollView = view.subviews[dividerIndex];
    MUTextView *textView = scrollView.documentView;

    NSUInteger numberOfLines = [textView numberOfLinesForHeight: proposedPosition - 1.0];
    position = [textView minimumHeightForLines: numberOfLines] + 1.0;
  }

  return position;
}

- (void) splitViewDidResizeSubviews: (NSNotification *) notification
{
  [self _prepareDelayedReportWindowSizeToServer];
}

#pragma mark - NSTextViewDelegate protocol

- (BOOL) textView: (NSTextView *) textView doCommandBySelector: (SEL) commandSelector
{
  if (textView == receivedTextView)
  {
    if ([[NSApp currentEvent] type] != NSKeyDown
        || commandSelector == @selector (moveUp:)
        || commandSelector == @selector (moveDown:)
        || commandSelector == @selector (scrollPageUp:)
        || commandSelector == @selector (scrollPageDown:)
        || commandSelector == @selector (scrollToBeginningOfDocument:)
        || commandSelector == @selector (scrollToEndOfDocument:))
    {
      return NO;
    }
    else if (commandSelector == @selector (insertNewline:)
             || commandSelector == @selector (insertTab:)
             || commandSelector == @selector (insertBacktab:))
    {
      [[self window] makeFirstResponder: inputTextView];
      return YES;
    }
    else
    {
      [inputTextView doCommandBySelector: commandSelector];
      [[self window] makeFirstResponder: inputTextView];
      return YES;
    }
  }
  else if (textView == inputTextView)
  {
    if ([NSApp currentEvent].type != NSKeyDown)
    {
      return NO;
    }
    else if (commandSelector == @selector (insertBacktab:))
    {
      [self _tabCompleteWithDirection: MUForwardSearch];
      return YES;
    }
    else if (commandSelector == @selector (insertNewline:))
    {
      unichar key = 0;
      
      if ([NSApp currentEvent].charactersIgnoringModifiers.length > 0)
        key = [[NSApp currentEvent].charactersIgnoringModifiers characterAtIndex: 0];
      
      if ([NSApp currentEvent].charactersIgnoringModifiers.length > 1)
        [self _endCompletion];
      
      if (key == NSCarriageReturnCharacter || key == NSEnterCharacter)
      {
        [self sendInputText: textView];
        return YES;
      }
    }
    else if (commandSelector == @selector (insertTab:))
    {
      [self _tabCompleteWithDirection: MUBackwardSearch];
      return YES;
    }
    else if (commandSelector == @selector (moveDown:))
    {
      unichar key = 0;
      
      if ([NSApp currentEvent].charactersIgnoringModifiers.length > 0)
        key = [[NSApp currentEvent].charactersIgnoringModifiers characterAtIndex: 0];
      
      [self _endCompletion];
      
      if (textView.selectedRange.location == textView.textStorage.length
          && key == NSDownArrowFunctionKey)
      {
        [self nextCommand: self];
        textView.selectedRange = NSMakeRange (textView.textStorage.length, 0);
        return YES;
      }
    }
    else if (commandSelector == @selector (moveUp:))
    {
      unichar key = 0;
      
      if ([NSApp currentEvent].charactersIgnoringModifiers.length > 0)
        key = [[NSApp currentEvent].charactersIgnoringModifiers characterAtIndex: 0];
      
      [self _endCompletion];
      
      if (textView.selectedRange.location == 0
          && key == NSUpArrowFunctionKey)
      {
        [self previousCommand: self];
        textView.selectedRange = NSMakeRange (0, 0);
        return YES;
      }
    }
    else if (commandSelector == @selector (scrollPageDown:)
             || commandSelector == @selector (scrollPageUp:)
             || commandSelector == @selector (scrollToBeginningOfDocument:)
             || commandSelector == @selector (scrollToEndOfDocument:))
    {
      [receivedTextView doCommandBySelector: commandSelector];
      return YES;
    }
  }
  return NO;
}

#pragma mark - NSWindowDelegate protocol

- (NSApplicationPresentationOptions) window: (NSWindow *) window
       willUseFullScreenPresentationOptions: (NSApplicationPresentationOptions) proposedOptions
{
  return proposedOptions | NSApplicationPresentationAutoHideToolbar;
}

- (void) windowDidBecomeKey: (NSNotification *) notification
{
  // Keep the font panel in sync with the current key window.
  
  if (self.connection.profile.font)
    [[NSFontManager sharedFontManager] setSelectedFont: self.connection.profile.font isMultiple: NO];
}

- (void) windowDidEnterFullScreen: (NSNotification *) notification
{
  if (_shouldScrollToBottomAfterFullScreenTransition)
    [self _scrollDisplayViewToBottom];
}

- (void) windowDidExitFullScreen: (NSNotification *) notification
{
  if (_shouldScrollToBottomAfterFullScreenTransition)
    [self _scrollDisplayViewToBottom];
}

- (void) windowDidResize: (NSNotification *) notification
{
  [self _prepareDelayedReportWindowSizeToServer];
  
  if (_shouldScrollToBottomAfterResize)
    [self _scrollDisplayViewToBottom];
}

- (BOOL) windowShouldClose: (id) sender
{
  if (self.connection.isConnectedOrConnecting)
  {
    [self confirmClose: NULL];
    return NO;
  }
  
  return YES;
}

- (void) windowWillClose: (NSNotification *) notification
{
  if (notification.object == self.window)
  {
    self.window.delegate = nil;
    
    [self _postConnectionWindowControllerWillCloseNotification];
  }
}

- (void) windowWillEnterFullScreen: (NSNotification *) notification
{
  _shouldScrollToBottomAfterFullScreenTransition = [self _shouldScrollDisplayViewToBottom];
  
  [self.window setContentBorderThickness: 0.0 forEdge: NSMinYEdge];

  timeConnectedField.hidden = YES;
  
  splitView.frame = NSMakeRect (splitView.frame.origin.x, -1.0,
                                splitView.frame.size.width, splitView.frame.size.height + 22.0);
}

- (void) windowWillExitFullScreen: (NSNotification *) notification
{
  _shouldScrollToBottomAfterFullScreenTransition = [self _shouldScrollDisplayViewToBottom];
  
  [self.window setContentBorderThickness: 22.0 forEdge: NSMinYEdge];
  
  timeConnectedField.hidden = NO;
  
  splitView.frame = NSMakeRect (splitView.frame.origin.x, 21.0,
                                splitView.frame.size.width, splitView.frame.size.height - 22.0);
}

- (NSSize) windowWillResize: (NSWindow *) sender toSize: (NSSize) frameSize
{
  _shouldScrollToBottomAfterResize = [self _shouldScrollDisplayViewToBottom];
  
  return NSMakeSize ([self _windowWidthForCandidateWidth: frameSize.width],
                     [self _windowHeightForCandidateHeight: frameSize.height]);
}

#pragma mark - Private methods

- (void) _clearPrompt
{
  if (_currentPrompt)
  {
    NSRange promptRange = NSMakeRange (_currentTextRangeWithoutPrompt.length,
                                       receivedTextView.textStorage.length - _currentTextRangeWithoutPrompt.length);

    [receivedTextView.textStorage beginEditing];
    [receivedTextView.textStorage deleteCharactersInRange: promptRange];
    [receivedTextView.textStorage endEditing];

    [receivedTextView.window invalidateCursorRectsForView: receivedTextView];

    _currentPrompt = nil;
    return;
  }
}

- (void) _displayAttributedString: (NSAttributedString *) attributedString
                  textDisplayMode: (enum MUTextDisplayModes) textDisplayMode
{
  if (attributedString.length == 0)
    return;

  BOOL needsScrollToBottom = NO;

  if ([self _shouldScrollDisplayViewToBottom])
    needsScrollToBottom = YES;

  if (textDisplayMode == MUPromptTextDisplayMode)
    _currentPrompt = [attributedString copy];

  [receivedTextView.textStorage beginEditing];

  if (_currentPrompt && textDisplayMode != MUEchoedTextDisplayMode)
  {
    NSRange promptRange = NSMakeRange (_currentTextRangeWithoutPrompt.length,
                                       receivedTextView.textStorage.length - _currentTextRangeWithoutPrompt.length);

    [receivedTextView.textStorage deleteCharactersInRange: promptRange];
  }

  [receivedTextView.textStorage appendAttributedString: attributedString];

  if (textDisplayMode != MUPromptTextDisplayMode)
  {
    _currentTextRangeWithoutPrompt = NSMakeRange (0, receivedTextView.textStorage.length);

    if (_currentPrompt && textDisplayMode == MUNormalTextDisplayMode)
      [receivedTextView.textStorage appendAttributedString: _currentPrompt];
  }

  [receivedTextView.textStorage endEditing];

  [receivedTextView.window invalidateCursorRectsForView: receivedTextView];

  if (needsScrollToBottom)
    [self _scrollDisplayViewToBottom];

  [self _postConnectionWindowControllerDidReceiveTextNotification];
}

- (void) _displaySystemMessage: (NSString *) string
{
  NSString *stringWithNewline = [NSString stringWithFormat: @"%@\n", string];

  NSMutableDictionary *attributes = [_connection.textAttributes mutableCopy];

  if (attributes[MUInverseColorsAttributeName])
    attributes[MUCustomBackgroundColorAttributeName] = @(MUSystemTextColorTag);
  else
    attributes[MUCustomForegroundColorAttributeName] = @(MUSystemTextColorTag);
  attributes[NSForegroundColorAttributeName] = self.connection.profile.effectiveSystemTextColor;

  [self _displayAttributedString: [[NSAttributedString alloc] initWithString: stringWithNewline attributes: attributes]
                 textDisplayMode: MUNormalTextDisplayMode];
}

- (void) _echoString: (NSString *) string
{
  if (!string || string.length == 0)
    return;
  
  NSMutableDictionary *attributes = [_connection.textAttributes mutableCopy];

  if (attributes[MUInverseColorsAttributeName])
    attributes[MUCustomBackgroundColorAttributeName] = @(MUSystemTextColorTag);
  else
    attributes[MUCustomForegroundColorAttributeName] = @(MUSystemTextColorTag);
  attributes[NSForegroundColorAttributeName] = self.connection.profile.effectiveSystemTextColor;

  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: string
                                                                         attributes: attributes];
  [self _displayAttributedString: attributedString textDisplayMode: MUEchoedTextDisplayMode];
}

- (void) _startDisplayingTimeConnected
{
  _timeConnectedFieldTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                              target: self
                                                            selector: @selector (_updateTimeConnectedField:)
                                                            userInfo: nil
                                                             repeats: YES];
}

- (void) _stopDisplayingTimeConnected
{
  [_timeConnectedFieldTimer invalidate];
  _timeConnectedFieldTimer = nil;

  timeConnectedField.stringValue = @"Disconnected";
}

- (void) _didEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
  if (returnCode == NSAlertAlternateReturn) /* Cancel. */
  {
    if (contextInfo)
      ((void (*) (id, SEL, BOOL)) objc_msgSend) ([NSApp delegate], (SEL) contextInfo, NO);
  }
}

- (void) _endCompletion
{
  _currentlySearching = NO;
  [_historyRing resetSearchCursor];
}

- (void) _postConnectionWindowControllerDidReceiveTextNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUConnectionWindowControllerDidReceiveTextNotification
                                                      object: self];
}

- (void) _postConnectionWindowControllerWillCloseNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUConnectionWindowControllerWillCloseNotification
                                                      object: self];
}

- (void) _prepareDelayedReportWindowSizeToServer
{
  if (_windowSizeNotificationTimer)
    [_windowSizeNotificationTimer invalidate];
  
  _windowSizeNotificationTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01
                                                                  target: self
                                                                selector: @selector (_triggerDelayedReportWindowSizeToServer:)
                                                                userInfo: nil
                                                                 repeats: NO];
}

- (void) _scrollDisplayViewToBottom
{
  [receivedTextView scrollRangeToVisible: NSMakeRange (receivedTextView.textStorage.length, 0) animate: YES];
}

- (void) _setTextViewsNeedDisplay: (NSNotification *) notification
{
  receivedTextView.needsDisplay = YES;
  inputTextView.needsDisplay = YES;
}

- (BOOL) _shouldScrollDisplayViewToBottom
{
  return (receivedTextView.enclosingScrollView.verticalScroller.isHidden
          || 1.0 - receivedTextView.enclosingScrollView.verticalScroller.floatValue < 0.000001);
}

- (NSString *) _splitViewAutosaveName
{
  return [NSString stringWithFormat: @"%@.split", self.connection.profile.uniqueIdentifier];
}

- (void) _tabCompleteWithDirection: (enum MUSearchDirections) direction
{
  NSString *currentPrefix;
  
  if (_currentlySearching)
  {
    currentPrefix = [[inputTextView.string copy] substringToIndex: inputTextView.selectedRange.location];
    
    if ([_historyRing numberOfUniqueMatchesForStringPrefix: currentPrefix] == 1)
    {
      inputTextView.selectedRange = NSMakeRange (inputTextView.textStorage.length, 0);
      [self _endCompletion];
      return;
    }
  }
  else
    currentPrefix = [inputTextView.string copy];
  
  NSString *foundString = (direction == MUBackwardSearch) ? [_historyRing searchBackwardForStringPrefix: currentPrefix]
                                                : [_historyRing searchForwardForStringPrefix: currentPrefix];
  
  if (foundString)
  {
    while ([foundString isEqualToString: inputTextView.string])
      foundString = (direction == MUBackwardSearch) ? [_historyRing searchBackwardForStringPrefix: currentPrefix]
                                                    : [_historyRing searchForwardForStringPrefix: currentPrefix];
    
    inputTextView.string = foundString;
    inputTextView.selectedRange = NSMakeRange (currentPrefix.length, inputTextView.textStorage.length - currentPrefix.length);
  }
  
  _currentlySearching = YES;
}

- (void) _triggerDelayedReportWindowSizeToServer: (NSTimer *) timer
{
  [_windowSizeNotificationTimer invalidate];
  _windowSizeNotificationTimer = nil;
  [self.connection reportWindowSizeToServer];
}

- (void) _updateANSIColorsForColor: (enum MUAbstractANSIColors) color
{
  NSColor *specifiedColor;
  enum MUCustomColorTags colorTagForANSI256;
  enum MUCustomColorTags colorTagForANSI16;
  BOOL changeIfBright;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  switch (color)
  {
    case MUANSIBlackColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
      colorTagForANSI256 = MUANSI256BlackColorTag;
      colorTagForANSI16 = MUANSIBlackColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIRedColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
      colorTagForANSI256 = MUANSI256RedColorTag;
      colorTagForANSI16 = MUANSIRedColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIGreenColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
      colorTagForANSI256 = MUANSI256GreenColorTag;
      colorTagForANSI16 = MUANSIGreenColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIYellowColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
      colorTagForANSI256 = MUANSI256YellowColorTag;
      colorTagForANSI16 = MUANSIYellowColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIBlueColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
      colorTagForANSI256 = MUANSI256BlueColorTag;
      colorTagForANSI16 = MUANSIBlueColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIMagentaColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
      colorTagForANSI256 = MUANSI256MagentaColorTag;
      colorTagForANSI16 = MUANSIMagentaColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSICyanColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
      colorTagForANSI256 = MUANSI256CyanColorTag;
      colorTagForANSI16 = MUANSICyanColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIWhiteColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
      colorTagForANSI256 = MUANSI256WhiteColorTag;
      colorTagForANSI16 = MUANSIWhiteColorTag;
      changeIfBright = NO;
      break;
      
    case MUANSIBrightBlackColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
      colorTagForANSI256 = MUANSIBrightBlackColorTag;
      colorTagForANSI16 = MUANSIBlackColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightRedColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
      colorTagForANSI256 = MUANSIBrightRedColorTag;
      colorTagForANSI16 = MUANSIRedColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightGreenColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
      colorTagForANSI256 = MUANSIBrightGreenColorTag;
      colorTagForANSI16 = MUANSIGreenColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightYellowColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
      colorTagForANSI256 = MUANSIBrightYellowColorTag;
      colorTagForANSI16 = MUANSIYellowColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightBlueColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
      colorTagForANSI256 = MUANSIBrightBlueColorTag;
      colorTagForANSI16 = MUANSIBlueColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightMagentaColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
      colorTagForANSI256 = MUANSIBrightMagentaColorTag;
      colorTagForANSI16 = MUANSIMagentaColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightCyanColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
      colorTagForANSI256 = MUANSIBrightCyanColorTag;
      colorTagForANSI16 = MUANSICyanColorTag;
      changeIfBright = YES;
      break;
      
    case MUANSIBrightWhiteColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
      colorTagForANSI256 = MUANSIBrightWhiteColorTag;
      colorTagForANSI16 = MUANSIWhiteColorTag;
      changeIfBright = YES;
      break;

    default:
      return;
  }
  
  NSUInteger index = 0;

  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];

    if ([attributes[MUCustomForegroundColorAttributeName] intValue] == colorTagForANSI256
        || ([attributes[MUCustomForegroundColorAttributeName] intValue] == colorTagForANSI16
            && ((changeIfBright && attributes[MUBrightColorAttributeName])
                || (!changeIfBright && !attributes[MUBrightColorAttributeName]))))
    {
      [receivedTextView.textStorage addAttribute: (attributes[MUInverseColorsAttributeName]
                                                   ? NSBackgroundColorAttributeName
                                                   : NSForegroundColorAttributeName)
                                           value: specifiedColor
                                           range: attributeRange];
    }
    
    if ([attributes[MUCustomBackgroundColorAttributeName] intValue] == colorTagForANSI256
        || ([attributes[MUCustomBackgroundColorAttributeName] intValue] == colorTagForANSI16
            && (!changeIfBright && !attributes[MUBrightColorAttributeName])))
    {
      [receivedTextView.textStorage addAttribute: (attributes[MUInverseColorsAttributeName]
                                                   ? NSForegroundColorAttributeName
                                                   : NSBackgroundColorAttributeName)
                                           value: specifiedColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  receivedTextView.needsDisplay = YES;
  inputTextView.needsDisplay = YES;
}

- (void) _updateBackgroundColor
{
  NSUInteger index = 0;
  
  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];
    
    if (attributes[MUInverseColorsAttributeName]
        && [attributes[MUCustomBackgroundColorAttributeName] intValue] == MUDefaultBackgroundColorTag)
    {
      [receivedTextView.textStorage addAttribute: NSForegroundColorAttributeName
                                           value: self.connection.profile.effectiveBackgroundColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  receivedTextView.needsDisplay = YES;
  inputTextView.needsDisplay = YES;
}

- (void) _updateFonts
{
  NSRect visibleRect = receivedTextView.enclosingScrollView.contentView.documentVisibleRect;
  NSRange visibleRange = [receivedTextView.layoutManager glyphRangeForBoundingRect: visibleRect
                                                                   inTextContainer: receivedTextView.textContainer];
  
  NSUInteger index = 0;
  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];
    
    if (attributes[MUBrightColorAttributeName]
        && [[NSUserDefaults standardUserDefaults] boolForKey: MUPDisplayBrightAsBold])
    {
      NSFont *effectiveFont = self.connection.profile.effectiveFont;
      
      [receivedTextView.textStorage addAttribute: NSFontAttributeName
                                           value: [effectiveFont boldFontWithRespectTo: effectiveFont]
                                           range: attributeRange];
    }
    else
    {
      [receivedTextView.textStorage addAttribute: NSFontAttributeName
                                           value: self.connection.profile.effectiveFont
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  inputTextView.font = self.connection.profile.effectiveFont;
  
  [receivedTextView scrollRangeToVisible: NSMakeRange (visibleRange.location + visibleRange.length, 0)];
  [inputTextView scrollRangeToVisible: NSMakeRange (inputTextView.textStorage.length, 0)];
  
  [self.connection reportWindowSizeToServer];
  
  receivedTextView.needsDisplay = YES;
  inputTextView.needsDisplay = YES;
}

- (void) _updateLinkTextColor
{
  NSMutableDictionary *linkTextAttributes = [receivedTextView.linkTextAttributes mutableCopy];
  
  linkTextAttributes[NSForegroundColorAttributeName] = self.connection.profile.effectiveLinkColor;
  
  receivedTextView.linkTextAttributes = linkTextAttributes;
  receivedTextView.needsDisplay = YES;
}

- (void) _updateSystemTextColor
{
  NSUInteger index = 0;

  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];

    // Presently we don't have a way for backgrounds to ever actually be set to the system text color, but if we do, this
    // implementation should be resilient to it. This does correctly handle system text written when we're in inverse
    // text mode, which also shouldn't really happen.

    if ([attributes[MUCustomForegroundColorAttributeName] intValue] == MUSystemTextColorTag)
    {
      [receivedTextView.textStorage addAttribute: (attributes[MUInverseColorsAttributeName]
                                                   ? NSBackgroundColorAttributeName
                                                   : NSForegroundColorAttributeName)
                                           value: self.connection.profile.effectiveSystemTextColor
                                           range: attributeRange];
    }
    
    if ([attributes[MUCustomBackgroundColorAttributeName] intValue] == MUSystemTextColorTag)
    {
      [receivedTextView.textStorage addAttribute: (attributes[MUInverseColorsAttributeName]
                                                   ? NSForegroundColorAttributeName
                                                   : NSBackgroundColorAttributeName)
                                           value: self.connection.profile.effectiveSystemTextColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }

  receivedTextView.needsDisplay = YES;
}

- (void) _updateTextColor
{
  NSUInteger index = 0;
  
  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];
    
    if ([attributes[MUCustomForegroundColorAttributeName] intValue] == MUDefaultForegroundColorTag)
    {
      [receivedTextView.textStorage addAttribute: (attributes[MUInverseColorsAttributeName]
                                                   ? NSBackgroundColorAttributeName
                                                   : NSForegroundColorAttributeName)
                                           value: self.connection.profile.effectiveTextColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  inputTextView.textColor = self.connection.profile.effectiveTextColor;
  
  receivedTextView.needsDisplay = YES;
  inputTextView.needsDisplay = YES;
}

- (void) _updateTimeConnectedField: (NSTimer *) timer
{
  NSDate *dateNow = [NSDate date];
  
  NSUInteger componentUnits = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
  NSDate *dateConnected = self.connection.dateConnected;
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components: componentUnits
                                                                     fromDate: dateConnected
                                                                       toDate: dateNow
                                                                      options: 0];
  
  if (dateComponents.day > 0)
    timeConnectedField.stringValue = [NSString stringWithFormat: @"%ld:%02ld:%02ld:%02ld",
                                      dateComponents.day, dateComponents.hour, dateComponents.minute,
                                      dateComponents.second];
  else if (dateComponents.hour > 0)
    timeConnectedField.stringValue = [NSString stringWithFormat: @"%ld:%02ld:%02ld",
                                      dateComponents.hour, dateComponents.minute, dateComponents.second];
  else
    timeConnectedField.stringValue = [NSString stringWithFormat: @"%ld:%02ld",
                                      dateComponents.minute, dateComponents.second];
}

- (void) _willEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
  if (returnCode == NSAlertDefaultReturn) /* Close. */
  {
    if (self.connection.isConnectedOrConnecting)
      [self.connection close];
    
    [self.window close];

    if (contextInfo)
      ((void (*) (id, SEL, BOOL)) objc_msgSend) ([NSApp delegate], (SEL) contextInfo, YES);
  }
}

- (CGFloat) _windowHeightForCandidateHeight: (CGFloat) candidateHeight
{
  // Explanation of the math here, because it's not as straightforward as width. The splitView.height =
  // receivedTextView.height + inputTextView.height + 1.0, where the 1.0 is the height of the splitter.
  //
  // The window height is splitView.height + 21.0. The bottom border is actually 22.0 pixels, but the splitView overlaps
  // the bottom border by one pixel for display reasons. So, the window total height = receivedTextView.height +
  // inputTextView.height + 1.0 + 21.0.
  //
  // We know that the receivedTextView and inputTextView have the same line heights, since we go to considerable trouble
  // to keep it that way, so we can get the number of lines for both views taken as an aggregate like this:

  NSUInteger totalTextViewLines = [receivedTextView numberOfLinesForHeight: candidateHeight - 22.0];

  // And then the total height is reassembled with the 22.0 missing height.

  return totalTextViewLines == 0 ? candidateHeight
                                 : [receivedTextView minimumHeightForLines: totalTextViewLines] + 22.0;
}

- (CGFloat) _windowWidthForCandidateWidth: (CGFloat) candidateWidth
{
  // Width is much easier, since the text views always have the same width as the window as a whole (and as each other).

  NSUInteger receivedTextViewColumns = [receivedTextView numberOfColumnsForWidth: candidateWidth];

  return receivedTextViewColumns == 0 ? candidateWidth
                                      : [receivedTextView minimumWidthForColumns: receivedTextViewColumns];
}

@end
