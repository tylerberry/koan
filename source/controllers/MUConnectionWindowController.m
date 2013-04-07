
//
// MUConnectionWindowController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectionWindowController.h"

#import "MULayoutManager.h"

#import "NSFont+Traits.h"

#import <objc/objc-runtime.h>

enum MUSearchDirections
{
  MUBackwardSearch,
  MUForwardSearch
};

enum MUAbstractANSIColors
{
  MUANSIBlackColor,
  MUANSIRedColor,
  MUANSIGreenColor,
  MUANSIYellowColor,
  MUANSIBlueColor,
  MUANSIMagentaColor,
  MUANSICyanColor,
  MUANSIWhiteColor,
  MUANSIBrightBlackColor,
  MUANSIBrightRedColor,
  MUANSIBrightGreenColor,
  MUANSIBrightYellowColor,
  MUANSIBrightBlueColor,
  MUANSIBrightMagentaColor,
  MUANSIBrightCyanColor,
  MUANSIBrightWhiteColor
};

@interface MUConnectionWindowController ()
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

- (void) _didEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
- (void) _endCompletion;
- (void) _postConnectionWindowControllerDidReceiveTextNotification;
- (void) _postConnectionWindowControllerWillCloseNotification;
- (void) _prepareDelayedReportWindowSizeToServer;
- (void) _scrollDisplayViewToBottom;
- (void) _setTextViewsNeedDisplay: (NSNotification *) notification;
- (BOOL) _shouldScrollDisplayViewToBottom;
- (NSString *) _splitViewAutosaveName;
- (void) _tabCompleteWithDirection: (enum MUSearchDirections) direction;
- (void) _triggerDelayedReportWindowSizeToServer: (NSTimer *) timer;
- (void) _updateANSIColorsForColor: (enum MUAbstractANSIColors) color;
- (void) _updateBackgroundColor;
- (void) _updateFonts;
- (void) _updateLinkTextColor;
- (void) _updateTextColor;
- (void) _updateTimeConnectedField: (NSTimer *) timer;
- (void) _willEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;

#pragma mark - User defaults key path string methods

- (NSString *) _keyPathForANSIBlackColor;
- (NSString *) _keyPathForANSIRedColor;
- (NSString *) _keyPathForANSIGreenColor;
- (NSString *) _keyPathForANSIYellowColor;
- (NSString *) _keyPathForANSIBlueColor;
- (NSString *) _keyPathForANSIMagentaColor;
- (NSString *) _keyPathForANSICyanColor;
- (NSString *) _keyPathForANSIWhiteColor;

- (NSString *) _keyPathForANSIBrightBlackColor;
- (NSString *) _keyPathForANSIBrightRedColor;
- (NSString *) _keyPathForANSIBrightGreenColor;
- (NSString *) _keyPathForANSIBrightYellowColor;
- (NSString *) _keyPathForANSIBrightBlueColor;
- (NSString *) _keyPathForANSIBrightMagentaColor;
- (NSString *) _keyPathForANSIBrightCyanColor;
- (NSString *) _keyPathForANSIBrightWhiteColor;

- (NSString *) _keyPathForDisplayBrightAsBold;

@end

#pragma mark -

@implementation MUConnectionWindowController

- (id) initWithProfile: (MUProfile *) newProfile
{
  if (!(self = [super initWithWindowNibName: @"MUConnectionWindow" owner: self]))
    return nil;
  
  _connectionController = [[MUMUDConnectionController alloc] initWithProfile: newProfile
                                                           fugueEditDelegate: self];
  _connectionController.delegate = self;
  
  _historyRing = [MUHistoryRing historyRing];
  
  _currentPrompt = nil;
  _currentTextRangeWithoutPrompt = NSMakeRange (0, 0);
  
  _currentlySearching = NO;
  _windowSizeNotificationTimer = nil;
  
  return self;
}

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer
{
  return [self initWithProfile: [MUProfile profileWithWorld: newWorld player: newPlayer]];
}

- (id) initWithWorld: (MUWorld *) newWorld
{
  return [self initWithWorld: newWorld player: nil];
}

- (void) awakeFromNib
{
  // Replace the layout manager with our custom one that doesn't ignore whitespace for underlining.
  
  [receivedTextView.textContainer replaceLayoutManager: [[MULayoutManager alloc] init]];
  receivedTextView.layoutManager.allowsNonContiguousLayout = YES;
  
  // On 10.7 and up we can set scroller knob colors.
  
  if ([receivedTextView.enclosingScrollView respondsToSelector: @selector (setScrollerKnobStyle:)])
    [receivedTextView.enclosingScrollView setScrollerKnobStyle: NSScrollerKnobStyleLight];
  
  if ([inputView.enclosingScrollView respondsToSelector: @selector (setScrollerKnobStyle:)])
    [inputView.enclosingScrollView setScrollerKnobStyle: NSScrollerKnobStyleLight];
  
  // And we can also enable fullscreen.
  
  if ([self.window respondsToSelector: @selector (setCollectionBehavior:)])
    [self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
  
  // And we can use the find bar and incremental searching.
  
  if ([receivedTextView respondsToSelector: @selector (setUsesFindBar:)])
    [receivedTextView setUsesFindBar: YES];
  
  if ([receivedTextView respondsToSelector: @selector (setIncrementalSearchingEnabled:)])
    [receivedTextView setIncrementalSearchingEnabled: YES];
  
  // Set the initial link text color.
  
  [self _updateLinkTextColor];
  
  // Restore window and split view title, size, and position.
  
  self.window.title = self.connectionController.profile.windowTitle;
  self.window.frameAutosaveName = self.connectionController.profile.uniqueIdentifier;
  self.window.frameUsingName = self.connectionController.profile.uniqueIdentifier;
  
  splitView.autosaveName = [self _splitViewAutosaveName];
  [splitView adjustSubviews];
  
  // Bindings and notifications.
  
  [receivedTextView bind: @"backgroundColor"
                toObject: self.connectionController.profile
             withKeyPath: @"effectiveBackgroundColor"
                 options: nil];
  
  [inputView bind: @"font"
         toObject: self.connectionController.profile
      withKeyPath: @"effectiveFont"
          options: nil];
  [inputView bind: @"textColor"
         toObject: self.connectionController.profile
      withKeyPath: @"effectiveTextColor"
          options: nil];
  [inputView bind: @"insertionPointColor"
         toObject: self.connectionController.profile
      withKeyPath: @"effectiveTextColor"
          options: nil];
  [inputView bind: @"backgroundColor"
         toObject: self.connectionController.profile
      withKeyPath: @"effectiveBackgroundColor"
          options: nil];
  
  [self.connectionController.profile addObserver: self
                                      forKeyPath: @"effectiveBackgroundColor"
                                         options: NSKeyValueObservingOptionNew
                                         context: nil];
  [self.connectionController.profile addObserver: self
                                      forKeyPath: @"effectiveFont"
                                         options: NSKeyValueObservingOptionNew
                                         context: nil];
  [self.connectionController.profile addObserver: self
                                      forKeyPath: @"effectiveLinkColor"
                                         options: NSKeyValueObservingOptionNew
                                         context: nil];
  [self.connectionController.profile addObserver: self
                                      forKeyPath: @"effectiveSystemTextColor"
                                         options: NSKeyValueObservingOptionNew
                                         context: nil];
  [self.connectionController.profile addObserver: self
                                      forKeyPath: @"effectiveTextColor"
                                         options: NSKeyValueObservingOptionNew
                                         context: nil];
  
  NSUserDefaultsController *sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBlackColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIRedColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIGreenColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIYellowColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBlueColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIMagentaColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSICyanColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIWhiteColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightBlackColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightRedColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightGreenColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightYellowColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightBlueColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightMagentaColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightCyanColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForANSIBrightWhiteColor]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
  
  [sharedDefaultsController addObserver: self
                             forKeyPath: [self _keyPathForDisplayBrightAsBold]
                                options: NSKeyValueObservingOptionNew
                                context: nil];
}

- (void) dealloc
{
  [self.connectionController disconnect];
  
  [self.connectionController.profile removeObserver: self forKeyPath: @"effectiveBackgroundColor"];
  [self.connectionController.profile removeObserver: self forKeyPath: @"effectiveFont"];
  [self.connectionController.profile removeObserver: self forKeyPath: @"effectiveLinkColor"];
  [self.connectionController.profile removeObserver: self forKeyPath: @"effectiveSystemTextColor"];
  [self.connectionController.profile removeObserver: self forKeyPath: @"effectiveTextColor"];
  
  NSUserDefaultsController *sharedDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBlackColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIRedColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIGreenColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIYellowColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBlueColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIMagentaColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSICyanColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIWhiteColor]];
  
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightBlackColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightRedColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightGreenColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightYellowColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightBlueColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightMagentaColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightCyanColor]];
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForANSIBrightWhiteColor]];
  
  [sharedDefaultsController removeObserver: self forKeyPath: [self _keyPathForDisplayBrightAsBold]];
  
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  [[NSNotificationCenter defaultCenter] removeObserver: nil name: nil object: self];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == self.connectionController.profile)
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
      //[self updateSystemTextColor];
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
    if ([keyPath isEqualToString: [self _keyPathForANSIBlackColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBlackColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIRedColor]])
    {
      [self _updateANSIColorsForColor: MUANSIRedColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIGreenColor]])
    {
      [self _updateANSIColorsForColor: MUANSIGreenColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIYellowColor]])
    {
      [self _updateANSIColorsForColor: MUANSIYellowColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBlueColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBlueColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIMagentaColor]])
    {
      [self _updateANSIColorsForColor: MUANSIMagentaColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSICyanColor]])
    {
      [self _updateANSIColorsForColor: MUANSICyanColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIWhiteColor]])
    {
      [self _updateANSIColorsForColor: MUANSIWhiteColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightBlackColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightBlackColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightRedColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightRedColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightGreenColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightGreenColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightYellowColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightYellowColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightBlueColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightBlueColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightMagentaColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightMagentaColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightCyanColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightCyanColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForANSIBrightWhiteColor]])
    {
      [self _updateANSIColorsForColor: MUANSIBrightWhiteColor];
      return;
    }
    else if ([keyPath isEqualToString: [self _keyPathForDisplayBrightAsBold]])
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
    if (self.connectionController.connection.isConnectedOrConnecting)
      [menuItem setTitle: _(MULDisconnect)];
    else
      [menuItem setTitle: _(MULConnect)];
    return YES;
  }
  else if (menuItemAction == @selector (clearWindow:))
  {
  	return YES;
  }
  return NO;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
  SEL toolbarItemAction = toolbarItem.action;
  
  if (toolbarItemAction == @selector (goToWorldURL:))
  {
    NSString *url = self.connectionController.profile.world.url;
    
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
  
  NSBeginAlertSheet ([NSString stringWithFormat: _(MULConfirmCloseTitle), self.connectionController.profile.windowTitle],
                     _(MULOK),
                     _(MULCancel),
                     nil,
                     self.window,
                     self,
                     @selector (_willEndCloseSheet:returnCode:contextInfo:),
                     @selector (_didEndCloseSheet:returnCode:contextInfo:),
                     (void *) callback,
                     _(MULConfirmCloseMessage),
                     self.connectionController.profile.hostname);
}

- (IBAction) clearWindow: (id) sender
{
  [receivedTextView setString: @""];
}

- (IBAction) connect: (id) sender
{
  [self.connectionController connect];
  
  [self.window makeFirstResponder: inputView];
}

- (IBAction) connectOrDisconnect: (id) sender
{
  if (self.connectionController.connection.isConnectedOrConnecting)
    [self disconnect: sender];
  else
    [self connect: sender];
}

- (IBAction) disconnect: (id) sender
{
  [self.connectionController disconnect];
}

- (IBAction) goToWorldURL: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: self.connectionController.profile.world.url]];
}

- (IBAction) sendInputText: (id) sender
{
  [self.connectionController sendString: inputView.string];
  
  if (!self.connectionController.connection.state.serverWillEcho)
  {
    [_historyRing saveString: inputView.string];
  
    if (_currentPrompt)
    {
      [self.connectionController echoString: [NSString stringWithFormat: @"%@\n", inputView.string]];
      _currentPrompt = nil;
    }
  }
  else if (_currentPrompt)
  {
    [self.connectionController echoString: @"\n"];
    _currentPrompt = nil;
  }
  
  [inputView setString: @""];
  [self.window makeFirstResponder: inputView];
}

- (IBAction) nextCommand: (id) sender
{
  [_historyRing updateString: inputView.string];
  [inputView setString: [_historyRing nextString]];
}

- (IBAction) previousCommand: (id) sender
{
  [_historyRing updateString: inputView.string];
  [inputView setString: [_historyRing previousString]];
}

#pragma mark - Filter delegate methods

- (void) clearScreen
{
  [self clearWindow: nil];
}

- (void) setInputViewString: (NSString *) string
{
  [inputView setString: string];
}

#pragma mark - MUMUDConnectionControllerDelegate protocol

- (void) clearPrompt
{
  if (_currentPrompt)
  {
    NSRange promptRange = NSMakeRange (_currentTextRangeWithoutPrompt.length,
                                       receivedTextView.textStorage.length - _currentTextRangeWithoutPrompt.length);
    
    [receivedTextView.textStorage deleteCharactersInRange: promptRange];
    _currentPrompt = nil;
    return;
  }
}

- (void) displayAttributedString: (NSAttributedString *) attributedString asPrompt: (BOOL) prompt
{
  BOOL needsScrollToBottom = NO;
  
  if ([self _shouldScrollDisplayViewToBottom])
    needsScrollToBottom = YES;
  
  if (prompt)
    _currentPrompt = [attributedString copy];
  
  if (_currentPrompt)
  {
    NSRange promptRange = NSMakeRange (_currentTextRangeWithoutPrompt.length,
                                       receivedTextView.textStorage.length - _currentTextRangeWithoutPrompt.length);
    
    [receivedTextView.textStorage deleteCharactersInRange: promptRange];
  }
  
  [receivedTextView.textStorage beginEditing];
  [receivedTextView.textStorage appendAttributedString: attributedString];
  [receivedTextView.textStorage endEditing];
  
  if (!prompt)
  {
    _currentTextRangeWithoutPrompt = NSMakeRange (0, receivedTextView.textStorage.length);
    
    if (_currentPrompt)
      [receivedTextView.textStorage appendAttributedString: _currentPrompt];
  }
  
  [receivedTextView.window invalidateCursorRectsForView: receivedTextView];
  
  if (needsScrollToBottom)
    [self _scrollDisplayViewToBottom];
  
  [self _postConnectionWindowControllerDidReceiveTextNotification];

}

- (void) reportWindowSizeToServer
{
  [self.connectionController sendNumberOfWindowLines: receivedTextView.numberOfLines
                                             columns: receivedTextView.numberOfColumns];
}

- (void) startDisplayingTimeConnected
{
  _timeConnectedFieldTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                              target: self
                                                            selector: @selector (_updateTimeConnectedField:)
                                                            userInfo: nil
                                                             repeats: YES];
}

- (void) stopDisplayingTimeConnected
{
  [_timeConnectedFieldTimer invalidate];
  _timeConnectedFieldTimer = nil;
  
  timeConnectedField.stringValue = @"Disconnected";
}

#pragma mark - MUTextViewPasteDelegate protocol

- (BOOL) textView: (MUTextView *) textView insertText: (id) string
{
  if (textView == receivedTextView)
  {
    [inputView insertText: string];
    [self.window makeFirstResponder: inputView];
    return YES;
  }
  else if (textView == inputView)
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
    [inputView pasteAsPlainText: originalSender];
    [self.window makeFirstResponder: inputView];
    return YES;
  }
  else if (textView == inputView)
  {
    [self _endCompletion];
    return NO;
  }
  return NO;
}

- (BOOL) textView: (MUTextView *) textView performFindPanelAction: (id) originalSender
{
  if (textView == inputView)
  {
    [receivedTextView performFindPanelAction: originalSender];
    return YES;
  }
  return NO;
}

#pragma mark - NSSplitViewDelegate protocol

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
      [[self window] makeFirstResponder: inputView];
      return YES;
    }
    else
    {
      [inputView doCommandBySelector: commandSelector];
      [[self window] makeFirstResponder: inputView];
      return YES;
    }
  }
  else if (textView == inputView)
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
  if (self.connectionController.connection.isConnectedOrConnecting)
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

  [timeConnectedField setHidden: YES];
  
  splitView.frame = NSMakeRect (splitView.frame.origin.x, 0.0,
                                splitView.frame.size.width, splitView.frame.size.height + 22.0);
}

- (void) windowWillExitFullScreen: (NSNotification *) notification
{
  _shouldScrollToBottomAfterFullScreenTransition = [self _shouldScrollDisplayViewToBottom];
  
  [self.window setContentBorderThickness: 22.0 forEdge: NSMinYEdge];
  
  [timeConnectedField setHidden: NO];
  
  splitView.frame = NSMakeRect (splitView.frame.origin.x, 22.0,
                                splitView.frame.size.width, splitView.frame.size.height - 22.0);
}

- (NSSize) windowWillResize: (NSWindow *) sender toSize: (NSSize) frameSize
{
  _shouldScrollToBottomAfterResize = [self _shouldScrollDisplayViewToBottom];
  
  return frameSize;
}

#pragma mark - Private methods

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
    return;
  
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
  [receivedTextView setNeedsDisplay: YES];
  [inputView setNeedsDisplay: YES];
}

- (BOOL) _shouldScrollDisplayViewToBottom
{
  return (receivedTextView.enclosingScrollView.verticalScroller.isHidden
          || 1.0 - receivedTextView.enclosingScrollView.verticalScroller.floatValue < 0.000001);
}

- (NSString *) _splitViewAutosaveName
{
  return [NSString stringWithFormat: @"%@.split", self.connectionController.profile.uniqueIdentifier];
}

- (void) _tabCompleteWithDirection: (enum MUSearchDirections) direction
{
  NSString *currentPrefix;
  
  if (_currentlySearching)
  {
    currentPrefix = [[inputView.string copy] substringToIndex: inputView.selectedRange.location];
    
    if ([_historyRing numberOfUniqueMatchesForStringPrefix: currentPrefix] == 1)
    {
      inputView.selectedRange = NSMakeRange (inputView.textStorage.length, 0);
      [self _endCompletion];
      return;
    }
  }
  else
    currentPrefix = [inputView.string copy];
  
  NSString *foundString = (direction == MUBackwardSearch) ? [_historyRing searchBackwardForStringPrefix: currentPrefix]
                                                : [_historyRing searchForwardForStringPrefix: currentPrefix];
  
  if (foundString)
  {
    while ([foundString isEqualToString: inputView.string])
      foundString = (direction == MUBackwardSearch) ? [_historyRing searchBackwardForStringPrefix: currentPrefix]
                                                    : [_historyRing searchForwardForStringPrefix: currentPrefix];
    
    inputView.string = foundString;
    inputView.selectedRange = NSMakeRange (currentPrefix.length, inputView.textStorage.length - currentPrefix.length);
  }
  
  _currentlySearching = YES;
}

- (void) _triggerDelayedReportWindowSizeToServer: (NSTimer *) timer
{
  [_windowSizeNotificationTimer invalidate];
  _windowSizeNotificationTimer = nil;
  [self.connectionController reportWindowSizeToServer];
}

- (void) _updateANSIColorsForColor: (enum MUAbstractANSIColors) color
{
  NSColor *specifiedColor;
  enum MUCustomColorTags colorTagForANSI256;
  enum MUCustomColorTags colorTagForANSI16;
  BOOL changeIfBold;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  switch (color)
  {
    case MUANSIBlackColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlackColor]];
      colorTagForANSI256 = MUANSI256BlackColorTag;
      colorTagForANSI16 = MUANSIBlackColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIRedColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIRedColor]];
      colorTagForANSI256 = MUANSI256RedColorTag;
      colorTagForANSI16 = MUANSIRedColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIGreenColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIGreenColor]];
      colorTagForANSI256 = MUANSI256GreenColorTag;
      colorTagForANSI16 = MUANSIGreenColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIYellowColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIYellowColor]];
      colorTagForANSI256 = MUANSI256YellowColorTag;
      colorTagForANSI16 = MUANSIYellowColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIBlueColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBlueColor]];
      colorTagForANSI256 = MUANSI256BlueColorTag;
      colorTagForANSI16 = MUANSIBlueColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIMagentaColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIMagentaColor]];
      colorTagForANSI256 = MUANSI256MagentaColorTag;
      colorTagForANSI16 = MUANSIMagentaColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSICyanColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSICyanColor]];
      colorTagForANSI256 = MUANSI256CyanColorTag;
      colorTagForANSI16 = MUANSICyanColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIWhiteColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIWhiteColor]];
      colorTagForANSI256 = MUANSI256WhiteColorTag;
      colorTagForANSI16 = MUANSIWhiteColorTag;
      changeIfBold = NO;
      break;
      
    case MUANSIBrightBlackColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlackColor]];
      colorTagForANSI256 = MUANSI256BrightBlackColorTag;
      colorTagForANSI16 = MUANSIBlackColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightRedColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightRedColor]];
      colorTagForANSI256 = MUANSI256BrightRedColorTag;
      colorTagForANSI16 = MUANSIRedColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightGreenColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightGreenColor]];
      colorTagForANSI256 = MUANSI256BrightGreenColorTag;
      colorTagForANSI16 = MUANSIGreenColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightYellowColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightYellowColor]];
      colorTagForANSI256 = MUANSI256BrightYellowColorTag;
      colorTagForANSI16 = MUANSIYellowColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightBlueColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightBlueColor]];
      colorTagForANSI256 = MUANSI256BrightBlueColorTag;
      colorTagForANSI16 = MUANSIBlueColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightMagentaColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightMagentaColor]];
      colorTagForANSI256 = MUANSI256BrightMagentaColorTag;
      colorTagForANSI16 = MUANSIMagentaColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightCyanColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightCyanColor]];
      colorTagForANSI256 = MUANSI256BrightCyanColorTag;
      colorTagForANSI16 = MUANSICyanColorTag;
      changeIfBold = YES;
      break;
      
    case MUANSIBrightWhiteColor:
      specifiedColor = [NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: MUPANSIBrightWhiteColor]];
      colorTagForANSI256 = MUANSI256BrightWhiteColorTag;
      colorTagForANSI16 = MUANSIWhiteColorTag;
      changeIfBold = YES;
      break;
  }
  
  NSUInteger index = 0;
  
  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];
    
    if ([attributes[MUCustomForegroundColorAttributeName] intValue] == colorTagForANSI256
        || ([attributes[MUCustomForegroundColorAttributeName] intValue] == colorTagForANSI16
            && ((changeIfBold && attributes[MUBoldFontAttributeName])
                || (!changeIfBold && !attributes[MUBoldFontAttributeName]))))
    {
      [receivedTextView.textStorage addAttribute: (attributes[MUInverseColorsAttributeName]
                                                   ? NSBackgroundColorAttributeName
                                                   : NSForegroundColorAttributeName)
                                           value: specifiedColor
                                           range: attributeRange];
    }
    
    if ([attributes[MUCustomBackgroundColorAttributeName] intValue] == colorTagForANSI256
        || ([attributes[MUCustomBackgroundColorAttributeName] intValue] == colorTagForANSI16
            && (!changeIfBold && !attributes[MUBoldFontAttributeName])))
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
  inputView.needsDisplay = YES;
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
                                           value: self.connectionController.profile.effectiveBackgroundColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  receivedTextView.needsDisplay = YES;
  inputView.needsDisplay = YES;
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
    
    if (attributes[MUBoldFontAttributeName]
        && [[NSUserDefaults standardUserDefaults] boolForKey: MUPDisplayBrightAsBold])
    {
      NSFont *effectiveFont = self.connectionController.profile.effectiveFont;
      
      [receivedTextView.textStorage addAttribute: NSFontAttributeName
                                           value: [effectiveFont boldFontWithRespectTo: effectiveFont]
                                           range: attributeRange];
    }
    else
    {
      [receivedTextView.textStorage addAttribute: NSFontAttributeName
                                           value: self.connectionController.profile.effectiveFont
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  [receivedTextView scrollRangeToVisible: NSMakeRange (visibleRange.location + visibleRange.length, 0)];
  [inputView scrollRangeToVisible: NSMakeRange (inputView.textStorage.length, 0)];
  
  [self.connectionController reportWindowSizeToServer];
  
  receivedTextView.needsDisplay = YES;
  inputView.needsDisplay = YES;
}

- (void) _updateLinkTextColor
{
  NSMutableDictionary *linkTextAttributes = [receivedTextView.linkTextAttributes mutableCopy];
  
  linkTextAttributes[NSForegroundColorAttributeName] = self.connectionController.profile.effectiveLinkColor;
  
  receivedTextView.linkTextAttributes = linkTextAttributes;
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
      [receivedTextView.textStorage addAttribute: ([attributes objectForKey: MUInverseColorsAttributeName]
                                                   ? NSBackgroundColorAttributeName
                                                   : NSForegroundColorAttributeName)
                                           value: self.connectionController.profile.effectiveTextColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  receivedTextView.needsDisplay = YES;
  inputView.needsDisplay = YES;
}

- (void) _updateTimeConnectedField: (NSTimer *) timer
{
  NSDate *dateNow = [NSDate date];
  
  NSUInteger componentUnits = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
  NSDate *dateConnected = self.connectionController.connection.dateConnected;
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
    if (self.connectionController.connection.isConnectedOrConnecting)
      [self.connectionController disconnect];
    
    [self.window close];

    if (contextInfo)
      ((void (*) (id, SEL, BOOL)) objc_msgSend) ([NSApp delegate], (SEL) contextInfo, YES);
  }
}

#pragma mark - User defaults key path string methods

- (NSString *) _keyPathForANSIBlackColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBlackColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIRedColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIRedColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIGreenColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIGreenColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIYellowColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIYellowColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBlueColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBlueColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIMagentaColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIMagentaColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSICyanColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSICyanColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIWhiteColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIWhiteColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightBlackColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightBlackColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightRedColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightRedColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightGreenColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightGreenColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightYellowColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightYellowColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightBlueColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightBlueColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightMagentaColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightMagentaColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightCyanColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightCyanColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForANSIBrightWhiteColor
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPANSIBrightWhiteColor]; });
  
  return keyPath;
}

- (NSString *) _keyPathForDisplayBrightAsBold
{
  static NSString *keyPath = nil;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{ keyPath = [@"values." stringByAppendingString: MUPDisplayBrightAsBold]; });
  
  return keyPath;
}

@end
