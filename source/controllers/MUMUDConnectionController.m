//
// MUMUDConnectionController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnectionController.h"

#import "MUFilterQueue.h"
#import "MUGrowlService.h"
#import "MUNaiveURLFilter.h"

static NSUInteger _droppedLines = 0;

enum MUTextDisplayModes
{
  MUSystemTextDisplayMode,
  MUNormalTextDisplayMode,
  MUPromptTextDisplayMode,
  MUEchoedTextDisplayMode
};

@interface MUMUDConnectionController ()
{  
  MUFilterQueue *_filterQueue;
  
  NSAttributedString *_currentRawPrompt;
  NSMutableArray *_recentReceivedStrings;
  
  NSTimer *_pingTimer;
}

- (void) _cleanUpPingTimer;
- (void) _sendPeriodicPing: (NSTimer *) timer;

@end

#pragma mark -

@implementation MUMUDConnectionController

@dynamic isConnectedOrConnecting;

- (id) initWithProfile: (MUProfile *) newProfile
     fugueEditDelegate: (NSObject <MUFugueEditFilterDelegate> *) fugueEditDelegate
{
  if (!(self = [super init]))
    return nil;
  
  _profile = newProfile;
  _connection = [_profile createNewTelnetConnectionWithDelegate: self];
  
  _filterQueue = [MUFilterQueue filterQueue];
  
  _recentReceivedStrings = [NSMutableArray array];
  
  [_filterQueue addFilter: [MUANSIFormattingFilter filterWithProfile: _profile delegate: self]];
  [_filterQueue addFilter: [MUFugueEditFilter filterWithProfile: _profile delegate: fugueEditDelegate]];
  [_filterQueue addFilter: [MUNaiveURLFilter filter]];
  [_filterQueue addFilter: [_profile createLogger]];
  
  return self;
}

#pragma mark - Actions

- (void) connect
{
  if (self.isConnectedOrConnecting)
    return;
  
  // if (!_connection) {  }  // TODO: Handle this error condition.
  
  [_connection open];
  
  _pingTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0
                                                target: self
                                              selector: @selector (_sendPeriodicPing:)
                                              userInfo: nil
                                               repeats: YES];
}

- (void) disconnect
{
  if (_connection)
    [_connection close];
}

- (void) echoString: (NSString *) string
{
  [self _displayString: string textDisplayMode: MUEchoedTextDisplayMode];
}

- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  [_connection sendNumberOfWindowLines: numberOfLines columns: numberOfColumns];
}

- (void) sendString: (NSString *) string
{
  [_connection writeLine: string];
}

#pragma mark - Property method implementations

- (BOOL) isConnectedOrConnecting
{
  return _connection.isConnected || _connection.isConnecting;
}

#pragma mark - MUMUDConnectionDelegate protocol

- (void) displayPrompt: (NSString *) promptString
{
  if (promptString && promptString.length > 0)
  {
    [self _displayString: promptString textDisplayMode: MUPromptTextDisplayMode];
  }
  else
    [self.delegate clearPrompt];
}

- (void) displayString: (NSString *) string
{
  if (string && string.length > 0)
  {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults boolForKey: MUPDropDuplicateLines])
    {
      if (![_recentReceivedStrings containsObject: string])
      {
        while (_recentReceivedStrings.count >= (NSUInteger) [defaults integerForKey: MUPDropDuplicateLinesCount])
        {
          [_recentReceivedStrings removeObjectAtIndex: 0];
        }
        
        [_recentReceivedStrings addObject: [string copy]];
      }
      else
      {
        ++_droppedLines;
        // NSLog (@"Dropped lines: %lu", ++_droppedLines);
        return;
      }
    }
    
    [self _displayString: string textDisplayMode: MUNormalTextDisplayMode];
  }
}

- (void) reportWindowSizeToServer
{
  [self.delegate reportWindowSizeToServer];
}

- (void) MUDConnectionDidConnect: (NSNotification *) notification
{
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionOpen)]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionOpenedForTitle: self.profile.windowTitle];
  
  [self.delegate startDisplayingTimeConnected];
  
  if (self.profile.hasLoginInformation)
    [_connection writeLine: self.profile.loginString];
}

- (void) MUDConnectionIsConnecting: (NSNotification *) notification
{
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionOpening)]
       textDisplayMode: MUSystemTextDisplayMode];
}

- (void) MUDConnectionWasClosedByClient: (NSNotification *) notification
{
  [self _cleanUpPingTimer];
  [self.delegate stopDisplayingTimeConnected];
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionClosed)]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionClosedForTitle: self.profile.windowTitle];
}

- (void) MUDConnectionWasClosedByServer: (NSNotification *) notification
{
  [self _cleanUpPingTimer];
  [self.delegate stopDisplayingTimeConnected];
  [self _displayString: [NSString stringWithFormat: @"%@\n", _(MULConnectionClosedByServer)]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionClosedByServerForTitle: self.profile.windowTitle];
}

- (void) MUDConnectionWasClosedWithError: (NSNotification *) notification
{
  [self _cleanUpPingTimer];
  [self.delegate stopDisplayingTimeConnected];
  
  NSString *errorMessage = notification.userInfo[MUMUDConnectionErrorMessageKey];
  
  [self _displayString: [NSString stringWithFormat: @"%@\n",
                         [NSString stringWithFormat: _(MULConnectionClosedByError), errorMessage]]
       textDisplayMode: MUSystemTextDisplayMode];
  [MUGrowlService connectionClosedByErrorForTitle: self.profile.windowTitle error: errorMessage];
}

#pragma mark - Private methods

- (void) _cleanUpPingTimer
{
  [_pingTimer invalidate];
  _pingTimer = nil;
}

- (void) _displayString: (NSString *) string textDisplayMode: (enum MUTextDisplayModes) textDisplayMode
{  
  NSAttributedString *attributedString = [NSAttributedString attributedStringWithString: string];
  
  switch (textDisplayMode)
  {
    case MUSystemTextDisplayMode:
    case MUNormalTextDisplayMode:
      [self.delegate displayAttributedString: [_filterQueue processCompleteLine: attributedString]];
      break;
      
    case MUPromptTextDisplayMode:
      _currentRawPrompt = [attributedString copy];
      [self.delegate displayAttributedStringAsPrompt: [_filterQueue processPartialLine: attributedString]];
      break;
      
    case MUEchoedTextDisplayMode:
    {
      NSAttributedString *fullLine;
      
      if (_currentRawPrompt)
      {
        NSMutableAttributedString *combinedLine = [_currentRawPrompt mutableCopy];
        [combinedLine appendAttributedString: attributedString];
        fullLine = combinedLine;
      }
      else
        fullLine = attributedString;
      
      [self.delegate displayAttributedString: [_filterQueue processCompleteLine: fullLine]];
      [self.delegate clearPrompt];
      break;
    }
  }
}

- (void) _sendPeriodicPing: (NSTimer *) timer
{
  if (_connection.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyPennMUSH
      || _connection.state.codebaseAnalyzer.codebase == MUCodebaseRhostMUSH)
    [_connection writeLine: @"IDLE"];
  else if (_connection.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH)
    [_connection writeLine: @"@@"];
}

@end
