//
// MUConnectionWindowController.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUConnectionWindowController.h"
#import "MUGrowlService.h"

#import "MUANSIFormattingFilter.h"
#import "MUNaiveURLFilter.h"
#import "MUFugueEditFilter.h"
#import "MUTextLogger.h"
#import "NSFont (Traits).h"

#import <objc/objc-runtime.h>

enum MUSearchDirections
{
  MUBackwardSearch,
  MUForwardSearch
};

enum MUTextDisplayModes
{
  MUSystemTextDisplayMode,
  MUNormalTextDisplayMode,
  MUPromptTextDisplayMode,
  MUEchoedTextDisplayMode
};

@interface MUConnectionWindowController ()
{
  MUProfile *profile;
  MUMUDConnection *telnetConnection;
  
  BOOL currentlySearching;
  
  NSTimer *pingTimer;
  MUFilterQueue *filterQueue;
  MUHistoryRing *historyRing;
  
  NSAttributedString *_currentPrompt;
  NSRange _currentTextRangeWithoutPrompt;
  
  NSTimer *windowSizeNotificationTimer;
}

- (BOOL) canCloseWindow;
- (void) cleanUpPingTimer;
- (MUFilter *) createLogger;
- (void) didEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;
- (void) disconnect;
- (void) _displayString: (NSString *) string textDisplayMode: (enum MUTextDisplayModes) textDisplayMode;
- (void) endCompletion;
- (BOOL) isUsingTelnet: (MUMUDConnection *) telnet;
- (void) postConnectionWindowControllerDidReceiveTextNotification;
- (void) postConnectionWindowControllerWillCloseNotification;
- (void) prepareDelayedReportWindowSizeToServer;
- (void) registerForNotifications;
- (void) sendPeriodicPing: (NSTimer *) timer;
- (void) setTextViewsNeedDisplay: (NSNotification *) notification;
- (NSString *) splitViewAutosaveName;
- (void) tabCompleteWithDirection: (enum MUSearchDirections) direction;
- (void) triggerDelayedReportWindowSizeToServer;
- (void) updateFonts;
- (void) updateLinkTextColor;
- (void) updateTextColors;
- (void) willEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo;

@end

#pragma mark -

@implementation MUConnectionWindowController

@dynamic isConnectedOrConnecting;

- (id) initWithProfile: (MUProfile *) newProfile
{
  if (!(self = [super initWithWindowNibName: @"MUConnectionWindow" owner: self]))
    return nil;
  
  profile = newProfile;
  
  historyRing = [MUHistoryRing historyRing];
  filterQueue = [MUFilterQueue filterQueue];
  
  [filterQueue addFilter: [MUANSIFormattingFilter filterWithProfile: profile delegate: self]];
  [filterQueue addFilter: [MUFugueEditFilter filterWithDelegate: self]];
  [filterQueue addFilter: [MUNaiveURLFilter filter]];
  [filterQueue addFilter: [self createLogger]];
  
  _currentPrompt = nil;
  _currentTextRangeWithoutPrompt = NSMakeRange (0, 0);
  currentlySearching = NO;
  windowSizeNotificationTimer = nil;
  
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
  // Initial window colors and fonts.
  
  receivedTextView.font = profile.effectiveFont;
  receivedTextView.textColor = profile.effectiveTextColor;
  
  [self updateLinkTextColor];
  
  // Restore window and split view title, size, and position.
  
  self.window.title = profile.windowTitle;
  self.window.frameAutosaveName = profile.uniqueIdentifier;
  self.window.frameUsingName = profile.uniqueIdentifier;
  
  splitView.autosaveName = self.splitViewAutosaveName;
  [splitView adjustSubviews];
  
  // Bindings and notifications.
  
  [inputView bind: @"font" toObject: profile withKeyPath: @"effectiveFont" options: nil];
  
  [profile addObserver: self forKeyPath: @"effectiveFont" options: NSKeyValueObservingOptionNew context: nil];
  [profile addObserver: self forKeyPath: @"effectiveLinkColor" options: NSKeyValueObservingOptionNew context: nil];
  [profile addObserver: self forKeyPath: @"effectiveTextColor" options: NSKeyValueObservingOptionNew context: nil];
  
  [receivedTextView bind: @"backgroundColor" toObject: profile withKeyPath: @"effectiveBackgroundColor" options: nil];
  
  [inputView bind: @"textColor" toObject: profile withKeyPath: @"effectiveTextColor" options: nil];
  [inputView bind: @"insertionPointColor" toObject: profile withKeyPath: @"effectiveTextColor" options: nil];
  [inputView bind: @"backgroundColor" toObject: profile withKeyPath: @"effectiveBackgroundColor" options: nil];
  
  [self registerForNotifications];
}

- (void) dealloc
{
  [self disconnect];
  
  [profile removeObserver: self forKeyPath: @"effectiveFont"];
  [profile removeObserver: self forKeyPath: @"effectiveLinkColor"];
  [profile removeObserver: self forKeyPath: @"effectiveTextColor"];
  
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  [[NSNotificationCenter defaultCenter] removeObserver: nil name: nil object: self];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object
                         change: (NSDictionary *) changeDictionary
                        context: (void *) context
{
  if (object == profile)
  {
    if ([keyPath isEqualToString: @"effectiveFont"])
    {
      [self updateFonts];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveLinkColor"])
    {
      [self updateLinkTextColor];
      return;
    }
    else if ([keyPath isEqualToString: @"effectiveTextColor"])
    {
      [self updateTextColors];
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
    if (self.isConnectedOrConnecting)
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
  SEL toolbarItemAction = [toolbarItem action];
  
  if (toolbarItemAction == @selector (goToWorldURL:))
  {
    NSString *url = profile.world.url;
    
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

- (BOOL) isConnectedOrConnecting
{
  return telnetConnection.isConnected || telnetConnection.isConnecting;
}

#pragma mark - Actions

- (void) confirmClose: (SEL) callback
{
  [self.window makeKeyAndOrderFront: nil];
  
  NSBeginAlertSheet ([NSString stringWithFormat: _(MULConfirmCloseTitle), profile.windowTitle],
                     _(MULOK),
                     _(MULCancel),
                     nil,
                     self.window,
                     self,
                     @selector (willEndCloseSheet:returnCode:contextInfo:),
                     @selector (didEndCloseSheet:returnCode:contextInfo:),
                     (void *) callback,
                     _(MULConfirmCloseMessage),
                     profile.hostname);
}

- (IBAction) clearWindow: (id) sender
{
  [receivedTextView setString: @""];
}

- (IBAction) connect: (id) sender
{
  if (self.isConnectedOrConnecting)
    return;
  if (!telnetConnection)
    telnetConnection = [profile createNewTelnetConnectionWithDelegate: self];
  // if (!telnetConnection) {  }  // TODO: Handle this error condition.
  
  [telnetConnection open];
  
  pingTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0
                                               target: self
                                             selector: @selector (sendPeriodicPing:)
                                             userInfo: nil
                                              repeats: YES];
  
  [[self window] makeFirstResponder: inputView];
}

- (IBAction) connectOrDisconnect: (id) sender
{
  if (self.isConnectedOrConnecting)
    [self disconnect: sender];
  else
    [self connect: sender];
}

- (IBAction) disconnect: (id) sender
{
  [self disconnect];
}

- (IBAction) goToWorldURL: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: profile.world.url]];
}

- (IBAction) sendInputText: (id) sender
{
  [telnetConnection writeLine: inputView.string];
  
  if (!telnetConnection.state.serverWillEcho)
  {
    [historyRing saveString: inputView.string];
  
    if (_currentPrompt)
    {
      [self _displayString: [NSString stringWithFormat: @"%@\n", inputView.string]
           textDisplayMode: MUEchoedTextDisplayMode];
      _currentPrompt = nil;
    }
  }
  else if (_currentPrompt)
  {
    [self _displayString: @"\n" textDisplayMode: MUEchoedTextDisplayMode];
    _currentPrompt = nil;
  }
  
  [inputView setString: @""];
  [self.window makeFirstResponder: inputView];
}

- (IBAction) nextCommand: (id) sender
{
  [historyRing updateString: inputView.string];
  [inputView setString: [historyRing nextString]];
}

- (IBAction) previousCommand: (id) sender
{
  [historyRing updateString: inputView.string];
  [inputView setString: [historyRing previousString] ];
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

#pragma mark - MUMUDConnectionDelegate protocol

- (void) displayPrompt: (NSString *) promptString
{
  [self _displayString: promptString textDisplayMode: MUPromptTextDisplayMode];
}

- (void) displayString: (NSString *) string
{  
  [self _displayString: string textDisplayMode: MUNormalTextDisplayMode];
}

- (void) reportWindowSizeToServer
{
  [telnetConnection sendNumberOfWindowLines: receivedTextView.numberOfLines
                                    columns: receivedTextView.numberOfColumns];
}

- (void) telnetConnectionDidConnect: (NSNotification *) notification
{
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionOpen)]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionOpenedForTitle: profile.windowTitle];
  
  if (profile.hasLoginInformation)
    [telnetConnection writeLine: profile.loginString];
}

- (void) telnetConnectionIsConnecting: (NSNotification *) notification
{
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionOpening)]
       textDisplayMode: MUSystemTextDisplayMode];
}

- (void) telnetConnectionWasClosedByClient: (NSNotification *) notification
{
  [self cleanUpPingTimer];
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionClosed)]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionClosedForTitle: profile.windowTitle];
}

- (void) telnetConnectionWasClosedByServer: (NSNotification *) notification
{
  [self cleanUpPingTimer];
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionClosedByServer)]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionClosedByServerForTitle: profile.windowTitle];
}

- (void) telnetConnectionWasClosedWithError: (NSNotification *) notification
{
  NSString *errorMessage = [[notification userInfo] valueForKey: MUMUDConnectionErrorMessageKey];
  [self cleanUpPingTimer];
  [self _displayString: [NSString stringWithFormat: @"%@\n",
                         [NSString stringWithFormat: _(MULConnectionClosedByError), errorMessage]]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionClosedByErrorForTitle: profile.windowTitle error: errorMessage];
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
    [self endCompletion];
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
    [self endCompletion];
    return NO;
  }
  return NO;
}

#pragma mark - NSSplitViewDelegate protocol

- (void) splitViewDidResizeSubviews: (NSNotification *) notification
{
  [self prepareDelayedReportWindowSizeToServer];
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
    if ([[NSApp currentEvent] type] != NSKeyDown)
    {
      return NO;
    }
    else if (commandSelector == @selector (insertBacktab:))
    {
      [self tabCompleteWithDirection: MUForwardSearch];
      return YES;
    }
    else if (commandSelector == @selector (insertNewline:))
    {
      unichar key = 0;
      
      if ([[[NSApp currentEvent] charactersIgnoringModifiers] length] > 0)
        key = [[[NSApp currentEvent] charactersIgnoringModifiers] characterAtIndex: 0];
      
      if ([[[NSApp currentEvent] charactersIgnoringModifiers] length] > 1)
      
      [self endCompletion];
      
      if (key == NSCarriageReturnCharacter || key == NSEnterCharacter)
      {
        [self sendInputText: textView];
        return YES;
      }
    }
    else if (commandSelector == @selector (insertTab:))
    {
      [self tabCompleteWithDirection: MUBackwardSearch];
      return YES;
    }
    else if (commandSelector == @selector (moveDown:))
    {
      unichar key = 0;
      
      if ([[[NSApp currentEvent] charactersIgnoringModifiers] length] > 0)
        key = [[[NSApp currentEvent] charactersIgnoringModifiers] characterAtIndex: 0];
      
      [self endCompletion];
      
      if (textView.selectedRange.location == textView.textStorage.length
          && key == NSDownArrowFunctionKey)
      {
        [self nextCommand: self];
        [textView setSelectedRange: NSMakeRange (textView.textStorage.length, 0)];
        return YES;
      }
    }
    else if (commandSelector == @selector (moveUp:))
    {
      unichar key = 0;
      
      if ([[NSApp currentEvent] charactersIgnoringModifiers].length > 0)
        key = [[[NSApp currentEvent] charactersIgnoringModifiers] characterAtIndex: 0];
      
      [self endCompletion];
      
      if (textView.selectedRange.location == 0
          && key == NSUpArrowFunctionKey)
      {
        [self previousCommand: self];
        [textView setSelectedRange: NSMakeRange (0, 0)];
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

- (void) windowDidResize: (NSNotification *) notification
{
  [self prepareDelayedReportWindowSizeToServer];
}

- (BOOL) windowShouldClose: (id) sender
{
  return self.canCloseWindow;
}

- (void) windowWillClose: (NSNotification *) notification
{
  if (notification.object == self.window)
  {
  	[self.window setDelegate: nil];
    
  	[self postConnectionWindowControllerWillCloseNotification];
  }
}

#pragma mark - Private methods

- (BOOL) canCloseWindow
{
  if (self.isConnectedOrConnecting)
  {
    [self confirmClose: NULL];
    return NO;
  }
  
  return YES;
}

- (void) cleanUpPingTimer
{
  [pingTimer invalidate];
  pingTimer = nil;  
}

- (MUFilter *) createLogger
{
  if (profile)
    return [profile createLogger];
  else
    return [MUTextLogger filter];
}

- (void) didEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
  if (returnCode == NSAlertAlternateReturn) /* Cancel. */
  {
    if (contextInfo)
      ((void (*) (id, SEL, BOOL)) objc_msgSend) ([NSApp delegate], (SEL) contextInfo, NO);
  }
}

- (void) disconnect
{
  if (telnetConnection)
    [telnetConnection close];
}

- (void) _displayString: (NSString *) string textDisplayMode: (enum MUTextDisplayModes) textDisplayMode
{
  if (!string || string.length == 0)
    return;
  
  BOOL forceScrollToBottom = NO;
  
  if (receivedTextView.enclosingScrollView.verticalScroller.isHidden)
    forceScrollToBottom = YES;
  
  NSAttributedString *attributedString = [NSAttributedString attributedStringWithString: string
                                                                             attributes: receivedTextView.typingAttributes];
  
  if (_currentPrompt)
  {
    NSRange promptRange = NSMakeRange (_currentTextRangeWithoutPrompt.length,
                                       receivedTextView.textStorage.length - _currentTextRangeWithoutPrompt.length);
    
    [receivedTextView.textStorage deleteCharactersInRange: promptRange];
  }
  
  switch (textDisplayMode)
  {
    case MUSystemTextDisplayMode:
    case MUNormalTextDisplayMode:
    {
      [receivedTextView.textStorage appendAttributedString: [filterQueue processCompleteLine: attributedString]];
      _currentTextRangeWithoutPrompt = NSMakeRange (0, receivedTextView.textStorage.length);
      
      if (_currentPrompt)
        [receivedTextView.textStorage appendAttributedString: [filterQueue processPartialLine: _currentPrompt]];
      
      break;
    }
      
    case MUPromptTextDisplayMode:
    {
      _currentPrompt = [attributedString copy];
      
      [receivedTextView.textStorage appendAttributedString: [filterQueue processPartialLine: attributedString]];
      
      break;
    }
      
    case MUEchoedTextDisplayMode:
    {
      NSMutableAttributedString *combinedString;
      
      if (_currentPrompt)
      {
        combinedString = [_currentPrompt mutableCopy];
        [combinedString appendAttributedString: attributedString];
      }
      else
      {
        NSLog (@"Warning: Echoed text without a prompt.");
        combinedString = [attributedString mutableCopy];
      }
      
      [receivedTextView.textStorage appendAttributedString: [filterQueue processCompleteLine: combinedString]];
      _currentTextRangeWithoutPrompt = NSMakeRange (0, receivedTextView.textStorage.length);
      break;
    }
  }
  
  [receivedTextView.window invalidateCursorRectsForView: receivedTextView];
  
  if (1.0 - receivedTextView.enclosingScrollView.verticalScroller.floatValue < 0.000001  // Avoid == for floats.
      || forceScrollToBottom)
  {
    [receivedTextView scrollRangeToVisible: NSMakeRange (receivedTextView.textStorage.length, 0)];
  }
  [self postConnectionWindowControllerDidReceiveTextNotification];  
}

- (void) endCompletion
{
  currentlySearching = NO;
  [historyRing resetSearchCursor];
}

- (BOOL) isUsingTelnet: (MUMUDConnection *) telnet
{
  return telnetConnection == telnet;
}

- (void) postConnectionWindowControllerDidReceiveTextNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUConnectionWindowControllerDidReceiveTextNotification
  																										object: self];
}

- (void) postConnectionWindowControllerWillCloseNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUConnectionWindowControllerWillCloseNotification
                                                      object: self];
}

- (void) registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (setTextViewsNeedDisplay:)
  																						 name: MUGlobalBackgroundColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (setTextViewsNeedDisplay:)
  																						 name: MUGlobalFontDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (setTextViewsNeedDisplay:)
  																						 name: MUGlobalTextColorDidChangeNotification
  																					 object: nil];
}

- (void) prepareDelayedReportWindowSizeToServer
{
  if (windowSizeNotificationTimer)
    return;
  
  windowSizeNotificationTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01
                                                                 target: self
                                                               selector: @selector (triggerDelayedReportWindowSizeToServer)
                                                               userInfo: nil
                                                                repeats: NO];
}

- (void) sendPeriodicPing: (NSTimer *) timer
{
  [telnetConnection writeLine: @"@@"];
}

- (void) setTextViewsNeedDisplay: (NSNotification *) notification
{
  [receivedTextView setNeedsDisplay: YES];
  [inputView setNeedsDisplay: YES];
}

- (NSString *) splitViewAutosaveName
{
  return [NSString stringWithFormat: @"%@.split", profile.uniqueIdentifier];
}

- (void) tabCompleteWithDirection: (enum MUSearchDirections) direction
{
  NSString *currentPrefix;
  
  if (currentlySearching)
  {
    currentPrefix = [[inputView.string copy] substringToIndex: inputView.selectedRange.location];
    
    if ([historyRing numberOfUniqueMatchesForStringPrefix: currentPrefix] == 1)
    {
      inputView.selectedRange = NSMakeRange (inputView.textStorage.length, 0);
      [self endCompletion];
      return;
    }
  }
  else
    currentPrefix = [inputView.string copy];
  
  NSString *foundString = (direction == MUBackwardSearch) ? [historyRing searchBackwardForStringPrefix: currentPrefix]
                                                : [historyRing searchForwardForStringPrefix: currentPrefix];
  
  if (foundString)
  {
    while ([foundString isEqualToString: inputView.string])
      foundString = (direction == MUBackwardSearch) ? [historyRing searchBackwardForStringPrefix: currentPrefix]
                                                    : [historyRing searchForwardForStringPrefix: currentPrefix];
    
    inputView.string = foundString;
    inputView.selectedRange = NSMakeRange (currentPrefix.length, inputView.textStorage.length - currentPrefix.length);
  }
  
  currentlySearching = YES;
}

- (void) triggerDelayedReportWindowSizeToServer
{
  [windowSizeNotificationTimer invalidate];
  windowSizeNotificationTimer = nil;
  [self reportWindowSizeToServer];
}

- (void) updateFonts
{
  NSRect visibleRect = receivedTextView.enclosingScrollView.contentView.documentVisibleRect;
  NSRange visibleRange = [receivedTextView.layoutManager glyphRangeForBoundingRect: visibleRect
                                                                   inTextContainer: receivedTextView.textContainer];
  
  NSUInteger index = 0;
  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];
    
    if (attributes[MUBoldFontAttributeName])
    {
      [receivedTextView.textStorage addAttribute: NSFontAttributeName
                                           value: [profile.effectiveFont boldFontWithRespectTo: profile.effectiveFont]
                                           range: attributeRange];
    }
    else
    {
      [receivedTextView.textStorage addAttribute: NSFontAttributeName
                                           value: profile.effectiveFont
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  [receivedTextView scrollRangeToVisible: NSMakeRange (visibleRange.location + visibleRange.length, 0)];
  [inputView scrollRangeToVisible: NSMakeRange (inputView.textStorage.length, 0)];
  
  [self reportWindowSizeToServer];
  
  [receivedTextView setNeedsDisplay: YES];
  [inputView setNeedsDisplay: YES];
}

- (void) updateLinkTextColor
{
  NSMutableDictionary *linkTextAttributes = [[receivedTextView linkTextAttributes] mutableCopy];
  linkTextAttributes[NSForegroundColorAttributeName] = profile.effectiveLinkColor;
  [receivedTextView setLinkTextAttributes: linkTextAttributes];
}

- (void) updateTextColors
{
  NSUInteger index = 0;
  
  while (index < receivedTextView.textStorage.length)
  {
    NSRange attributeRange;
    NSDictionary *attributes = [receivedTextView.textStorage attributesAtIndex: index effectiveRange: &attributeRange];
    
    if (!attributes[MUCustomColorAttributeName])
    {
      [receivedTextView.textStorage addAttribute: NSForegroundColorAttributeName
                                           value: profile.effectiveTextColor
                                           range: attributeRange];
    }
    
    index += attributeRange.length;
  }
  
  [receivedTextView setNeedsDisplay: YES];
  [inputView setNeedsDisplay: YES];
}

- (void) willEndCloseSheet: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
  if (returnCode == NSAlertDefaultReturn) /* Close. */
  {
    if (self.isConnectedOrConnecting)
      [self disconnect];
    
    [self.window close];

    if (contextInfo)
      ((void (*) (id, SEL, BOOL)) objc_msgSend) ([NSApp delegate], (SEL) contextInfo, YES);
  }
}

@end
