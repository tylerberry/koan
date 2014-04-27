//
// MUMUDConnectionController.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnectionController.h"

#import "MUAutoHyperlinksFilter.h"
#import "MUFilterQueue.h"
#import "MUGrowlService.h"
#import "MURegexTestFilter.h"

static NSUInteger _droppedLines = 0;

enum MUTextDisplayModes
{
  MUSystemTextDisplayMode,
  MUNormalTextDisplayMode,
  MUPromptTextDisplayMode,
  MUEchoedTextDisplayMode
};

@interface MUMUDConnectionController ()

- (void) _attemptReconnect;
- (void) _cleanUpPingTimer;
- (void) _clearRecentReceivedStrings: (NSTimer *) timer;
- (void) _displayAttributedString: (NSAttributedString *) string
                  textDisplayMode: (enum MUTextDisplayModes) textDisplayMode;
- (void) _displaySystemMessage: (NSString *) string;
- (void) _resetRecentStrings;
- (void) _sendPeriodicPing: (NSTimer *) timer;

@end

#pragma mark -

@implementation MUMUDConnectionController
{
  MUFilterQueue *_filterQueue;

  NSAttributedString *_currentRawPrompt;
  NSString *_recentSentString;
  NSMutableArray *_recentReceivedStrings;
  NSTimer *_clearRecentReceivedStringTimer;
  NSUInteger _reconnectCount;

  NSTimer *_pingTimer;
}

- (id) initWithProfile: (MUProfile *) newProfile
     fugueEditDelegate: (NSObject <MUFugueEditFilterDelegate> *) fugueEditDelegate
{
  if (!(self = [super init]))
    return nil;
  
  _profile = newProfile;
  _connection = [_profile createNewMUDConnectionWithDelegate: self];
  
  _filterQueue = [MUFilterQueue filterQueue];
  
  //[_filterQueue addFilter: [MUANSIFormattingFilter filterWithProfile: _profile delegate: self]];
  [_filterQueue addFilter: [MUFugueEditFilter filterWithProfile: _profile delegate: fugueEditDelegate]];
  [_filterQueue addFilter: [MUAutoHyperlinksFilter filter]];
  [_filterQueue addFilter: [MURegexTestFilter filter]];
  [_filterQueue addFilter: [_profile createLogger]];
  
  _currentRawPrompt = nil;
  _recentReceivedStrings = [NSMutableArray array];
  _recentSentString = nil;
  _reconnectCount = 0;
  _clearRecentReceivedStringTimer = nil;
  
  _pingTimer = nil;
  
  return self;
}

#pragma mark - Actions

- (void) connect
{
  if (_connection.isConnectedOrConnecting)
    return;
  
  [_connection open];
  
  _pingTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0
                                                target: self
                                              selector: @selector (_sendPeriodicPing:)
                                              userInfo: nil
                                               repeats: YES];
}

- (void) disconnect
{
  [_connection close];
}

- (void) echoString: (NSString *) string
{
  NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor redColor]};
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: string
                                                                         attributes: attributes];
  [self _displayAttributedString: attributedString textDisplayMode: MUEchoedTextDisplayMode];
}

- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  [_connection sendNumberOfWindowLines: numberOfLines columns: numberOfColumns];
}

- (void) sendString: (NSString *) string
{
  _recentSentString = [string copy];
  [_connection writeLine: string];
}

#pragma mark - MUMUDConnectionDelegate protocol

- (void) displayAttributedString: (NSAttributedString *) attributedString
{
  if (attributedString && attributedString.length > 0)
  {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([_recentReceivedStrings containsObject: attributedString.string]
        && ![attributedString.string isEqualToString: @"\n"])             // Exclude blank lines from filtering.
    {
      if ([defaults boolForKey: MUPDropDuplicateLines])
      {
        ++_droppedLines;
        // NSLog (@"Dropped lines: %lu", ++_droppedLines);
        return;
      }
    }
    else
    {
      while (_recentReceivedStrings.count >= (NSUInteger) [defaults integerForKey: MUPDropDuplicateLinesCount])
        [_recentReceivedStrings removeObjectAtIndex: 0];

      [_recentReceivedStrings addObject: [attributedString.string copy]];
    }

    if (_clearRecentReceivedStringTimer.isValid)
      [_clearRecentReceivedStringTimer invalidate];

    _clearRecentReceivedStringTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                                       target: self
                                                                     selector: @selector (_clearRecentReceivedStrings:)
                                                                     userInfo: nil
                                                                      repeats: NO];

    [self _displayAttributedString: attributedString textDisplayMode: MUNormalTextDisplayMode];
  }
}

- (void) displayAttributedStringAsPrompt: (NSAttributedString *) attributedString
{
  if (attributedString && attributedString.length > 0)
  {
    [self _displayAttributedString: attributedString textDisplayMode: MUPromptTextDisplayMode];
  }
  else
    [self.delegate clearPrompt];
}

- (void) reportWindowSizeToServer
{
  [self.delegate reportWindowSizeToServer];
}

- (void) MUDConnectionDidConnect: (NSNotification *) notification
{
  _reconnectCount = 0;
  
  [self _displaySystemMessage: _(MULConnectionOpen)];
  [MUGrowlService connectionOpenedForTitle: self.profile.windowTitle];
  
  [self.delegate startDisplayingTimeConnected];
  
  if (self.profile.hasLoginInformation)
    [_connection writeLine: self.profile.loginString];
}

- (void) MUDConnectionIsConnecting: (NSNotification *) notification
{
  [self _displaySystemMessage: _(MULConnectionOpening)];
}

- (void) MUDConnectionWasClosedByClient: (NSNotification *) notification
{
  [self _cleanUpPingTimer];
  [self.delegate stopDisplayingTimeConnected];
  [self _resetRecentStrings];
  [self _displaySystemMessage: _(MULConnectionClosed)];
  [MUGrowlService connectionClosedForTitle: self.profile.windowTitle];
}

- (void) MUDConnectionWasClosedByServer: (NSNotification *) notification
{
  [self _cleanUpPingTimer];
  [self.delegate stopDisplayingTimeConnected];
  [self _resetRecentStrings];
  [self _displaySystemMessage: _(MULConnectionClosedByServer)];
  [MUGrowlService connectionClosedByServerForTitle: self.profile.windowTitle];
  
  [self _attemptReconnect];
}

- (void) MUDConnectionWasClosedWithError: (NSNotification *) notification
{
  [self _cleanUpPingTimer];
  [self.delegate stopDisplayingTimeConnected];
  [self _resetRecentStrings];
  
  NSError *error = notification.userInfo[MUMUDConnectionErrorKey];
  
  [MUGrowlService connectionClosedByErrorForTitle: self.profile.windowTitle error: error];
  
  if (error)
  {
    [self _displaySystemMessage: [NSString stringWithFormat: _(MULConnectionClosedByError), error.localizedDescription]];
  }
  else
  {
    [self _displaySystemMessage: [NSString stringWithFormat: _(MULConnectionClosedByError), _(MULConnectionNoErrorAvailable)]];
  }
  
  [self _attemptReconnect];
}

#pragma mark - Private methods

- (void) _attemptReconnect
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ([defaults boolForKey: MUPAutomaticReconnect]
      && ++_reconnectCount < (NSUInteger) [defaults integerForKey: MUPAutomaticReconnectCount]
      && !([_recentSentString isEqualToString: @"QUIT"]
           || [_recentSentString isEqualToString: @"@shutdown"]))
    [self connect];
}

- (void) _cleanUpPingTimer
{
  [_pingTimer invalidate];
  _pingTimer = nil;
}

- (void) _clearRecentReceivedStrings: (NSTimer *) timer
{
  _recentReceivedStrings = [NSMutableArray array];
}

- (void) _displayAttributedString: (NSAttributedString *) attributedString
                  textDisplayMode: (enum MUTextDisplayModes) textDisplayMode
{
  switch (textDisplayMode)
  {
    case MUSystemTextDisplayMode:
    case MUNormalTextDisplayMode:
      [self.delegate displayAttributedString: [_filterQueue processCompleteLine: attributedString] asPrompt: NO];
      break;
      
    case MUPromptTextDisplayMode:
      _currentRawPrompt = [attributedString copy];
      [self.delegate displayAttributedString: [_filterQueue processPartialLine: attributedString] asPrompt: YES];
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
      
      [self.delegate displayAttributedString: [_filterQueue processCompleteLine: fullLine] asPrompt: NO];
      [self.delegate clearPrompt];
      break;
    }
  }
}

- (void) _displaySystemMessage: (NSString *) string
{
  NSString *stringWithNewline = [NSString stringWithFormat: @"%@\n", string];

  [self _displayAttributedString: [[NSAttributedString alloc] initWithString: stringWithNewline attributes: nil]
                 textDisplayMode: MUSystemTextDisplayMode];
}

- (void) _resetRecentStrings
{
  _recentReceivedStrings = [NSMutableArray array];
}

- (void) _sendPeriodicPing: (NSTimer *) timer
{
  if (_connection.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyPennMUSH
      || _connection.state.codebaseAnalyzer.codebase == MUCodebaseRhostMUSH)
    [_connection writeLine: @"IDLE"];
  else if (_connection.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH)
    [_connection writeLine: @"@@"];
  else if (_connection.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyEvennia)
    [_connection writeLine: @"idle"];
}

@end
