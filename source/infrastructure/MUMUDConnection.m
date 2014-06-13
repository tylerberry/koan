//
// MUMUDConnection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnection.h"
#import "MUAbstractConnectionSubclass.h"

#import "MUAutoHyperlinksFilter.h"
#import "MUFilterQueue.h"
#import "MUNewlineTextAttributeFilter.h"
#import "NSFont+Traits.h"

NSString *MUMUDConnectionDidConnectNotification = @"MUMUDConnectionDidConnectNotification";
NSString *MUMUDConnectionIsConnectingNotification = @"MUMUDConnectionIsConnectingNotification";
NSString *MUMUDConnectionWasClosedByClientNotification = @"MUMUDConnectionWasClosedByClientNotification";
NSString *MUMUDConnectionWasClosedByServerNotification = @"MUMUDConnectionWasClosedByServerNotification";
NSString *MUMUDConnectionWasClosedWithErrorNotification = @"MUMUDConnectionWasClosedWithErrorNotification";
NSString *MUMUDConnectionErrorKey = @"MUMUDConnectionErrorKey";

@interface MUMUDConnection ()

- (void) _attemptReconnect;
- (void) _cleanUpPingTimer;
- (void) _reset;
- (void) _registerObjectForNotifications: (id) object;
- (void) _sendPeriodicPing: (NSTimer *) pingTimer;
- (void) _unregisterObjectForNotifications: (id) object;
- (void) _writeBufferedDataToOutputStream;
- (void) _writeDataWithPreprocessing: (NSData *) data;

@end

#pragma mark -

@implementation MUMUDConnection
{
  NSInputStream *_inputStream;
  NSOutputStream *_outputStream;
  BOOL _outputStreamHasSpaceAvailable;

  NSMutableData *_outgoingDataBuffer;
  NSMutableAttributedString *_incomingLineBuffer;

  MUProtocolStack *_protocolStack;
  MUTelnetProtocolHandler *_telnetProtocolHandler;
  MUTerminalProtocolHandler *_terminalProtocolHandler;
  MUFilterQueue *_filterQueue;

  NSString *_lastSentLine;
  NSUInteger _lastNumberOfColumns;
  NSUInteger _lastNumberOfLines;

  NSUInteger _droppedLines;
  NSMutableArray *_recentReceivedStrings;
  NSTimer *_clearRecentReceivedStringTimer;

  NSUInteger _reconnectCount;

  NSTimer *_pingTimer;
}

@dynamic textAttributes;

+ (instancetype) connectionWithProfile: (MUProfile *) profile
                              delegate: (NSObject <MUMUDConnectionDelegate, MUFugueEditFilterDelegate> *) delegate
{
  return [[self alloc] initWithProfile: profile delegate: delegate];
}

- (instancetype) initWithProfile: (MUProfile *) profile
                        delegate: (NSObject <MUMUDConnectionDelegate, MUFugueEditFilterDelegate> *) newDelegate
{
  if (!(self = [super init]))
    return nil;
  
  _inputStream = nil;
  _outputStream = nil;
  _outputStreamHasSpaceAvailable = NO;
  
  _outgoingDataBuffer = [[NSMutableData alloc] init];
  _incomingLineBuffer = [[NSMutableAttributedString alloc] init];
  
  _state = [[MUMUDConnectionState alloc] initWithCodebaseAnalyzerDelegate: self];
  _dateConnected = nil;
  _profile = profile;

  _lastSentLine = nil;
  _lastNumberOfColumns = 0;
  _lastNumberOfLines = 0;

  _droppedLines = 0;
  _recentReceivedStrings = [NSMutableArray array];
  _clearRecentReceivedStringTimer = nil;

  _reconnectCount = 0;
  
  _protocolStack = [[MUProtocolStack alloc] initWithConnectionState: _state];
  _protocolStack.delegate = self;
  
  // Ordering is important for byte protocol handlers: they should be added in
  // order with respect to outgoing data, and reverse order with respect to
  // incoming data.
  
  MUMCPProtocolHandler *mcpProtocolHandler = [MUMCPProtocolHandler protocolHandlerWithConnectionState: _state];
  mcpProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: mcpProtocolHandler];

  _terminalProtocolHandler = [MUTerminalProtocolHandler protocolHandlerWithProfile: _profile connectionState: _state];
  _terminalProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: _terminalProtocolHandler];
  
  _telnetProtocolHandler = [MUTelnetProtocolHandler protocolHandlerWithConnectionState: _state];
  _telnetProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: _telnetProtocolHandler];
  
  MUMCCPProtocolHandler *mccpProtocolHandler = [MUMCCPProtocolHandler protocolHandlerWithConnectionState: _state];
  mccpProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: mccpProtocolHandler];

  _filterQueue = [MUFilterQueue filterQueue];

  [_filterQueue addFilter: [MUFugueEditFilter filterWithProfile: _profile delegate: newDelegate]];
  [_filterQueue addFilter: [MUNewlineTextAttributeFilter filter]];
  [_filterQueue addFilter: [MUAutoHyperlinksFilter filter]];
  [_filterQueue addFilter: [_profile createLogger]];
  
  _delegate = newDelegate;
  if (_delegate)
    [self _registerObjectForNotifications: _delegate];
  
  return self;
}

- (void) dealloc
{
  [self _cleanUpPingTimer];
  [self close];

  [self _unregisterObjectForNotifications: _delegate];
  _delegate = nil;
}

- (void) setDelegate: (NSObject <MUMUDConnectionDelegate> *) object
{
  if (_delegate == object)
    return;
  
  [self _unregisterObjectForNotifications: _delegate];
  [self _registerObjectForNotifications: object];
  
  _delegate = object;
}

- (NSDictionary *) textAttributes
{
  return _terminalProtocolHandler.textAttributes;
}

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  [self log: message arguments: args];
  
  va_end (args);
}

- (void) writeLine: (NSString *) line
{
  _lastSentLine = [line copy];
  NSString *lineWithLineEnding = [NSString stringWithFormat: @"%@\r\n", line];
  NSData *encodedData = [lineWithLineEnding dataUsingEncoding: self.state.stringEncoding allowLossyConversion: YES];
  [self _writeDataWithPreprocessing: encodedData];
}

#pragma mark - MUAbstractConnection overrides

- (void) close
{
  if (self.isConnectedOrConnecting)
    [self setStatusClosedByClient];
}

- (void) open
{
  CFReadStreamRef readStream;
  CFWriteStreamRef writeStream;
  
  CFStreamCreatePairWithSocketToHost (NULL,
                                      (__bridge CFStringRef) _profile.world.hostname,
                                      (UInt32) _profile.world.port.integerValue,
                                      &readStream,
                                      &writeStream);
  
  _inputStream = (__bridge_transfer NSInputStream *) readStream;
  _outputStream = (__bridge_transfer NSOutputStream *) writeStream;
  
  _inputStream.delegate = self;
  _outputStream.delegate = self;
  
  if (_profile.world.forceTLS)
    [self enableTLS];
  
  [_inputStream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_outputStream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  
  [self setStatusConnecting];
  
  [_inputStream open];
  [_outputStream open];
}

- (void) setStatusConnected
{
  [super setStatusConnected];
  
  _dateConnected = [NSDate date];
  _reconnectCount = 0;

  _pingTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0
                                                target: self
                                              selector: @selector (_sendPeriodicPing:)
                                              userInfo: nil
                                               repeats: YES];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionDidConnectNotification
                                                      object: self];
}

- (void) setStatusConnecting
{
  [super setStatusConnecting];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionIsConnectingNotification
                                                      object: self];
}

- (void) setStatusClosedByClient
{
  [super setStatusClosedByClient];
  [self _reset];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByClientNotification
                                                      object: self];
}

- (void) setStatusClosedByServer
{
  [super setStatusClosedByServer];
  [self _reset];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByServerNotification
                                                      object: self];

  [self _attemptReconnect];
}

- (void) setStatusClosedWithError: (NSError *) error
{
  [super setStatusClosedWithError: error];
  [self _reset];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedWithErrorNotification
                                                      object: self
                                                    userInfo: @{MUMUDConnectionErrorKey: error}];
  [self _attemptReconnect];
}

#pragma mark - Various protocols for delegates

- (void) log: (NSString *) message arguments: (va_list) args
{
  NSLog (@"[%@:%@] %@", _profile.world.hostname, _profile.world.port, [[NSString alloc] initWithFormat: message arguments: args]);
}

#pragma mark - NSStreamDelegate protocol

- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) eventCode
{
  switch (eventCode)
  {
    case NSStreamEventNone:
      return;
      
    case NSStreamEventOpenCompleted:
      if (stream == _inputStream)
        [self setStatusConnected];
      return;
      
    case NSStreamEventEndEncountered:
      if (stream == _inputStream)
      {
        [self setStatusClosedByServer];
      }
      return;
      
    case NSStreamEventErrorOccurred:
      [self setStatusClosedWithError: stream.streamError];
      return;
      
    case NSStreamEventHasBytesAvailable:
      if (stream == _inputStream)
      {
        unsigned numberOfBytesToRead = _state.needsSingleByteSocketReads ? 1 : 1024;
        uint8_t *bytes = calloc (numberOfBytesToRead, sizeof (uint8_t));
        NSInteger readLength = [_inputStream read: bytes maxLength: numberOfBytesToRead];
        
        if (readLength == 0)
        {
          free (bytes);
          [self setStatusClosedByServer];
        }
        else if (readLength < 0) // Error reading.
        {
          free (bytes);
        }
        else
        {
          NSData *receivedData = [NSData dataWithBytesNoCopy: bytes length: readLength freeWhenDone: YES];

          [_protocolStack parseInputData: receivedData];
        }
        
        if (!_inputStream.hasBytesAvailable)
          [_protocolStack maybeUseBufferedDataAsPrompt];
      }
      return;
      
    case NSStreamEventHasSpaceAvailable:
      if (stream == _outputStream)
      {
        if (_outgoingDataBuffer.length > 0)
          [self _writeBufferedDataToOutputStream];
        else
          _outputStreamHasSpaceAvailable = YES;
      }
      return;
  }
}

#pragma mark - MUProtocolStackDelegate protocol

- (void) appendStringToLineBuffer: (NSString *) string
{
  if (!string || string.length == 0)
    return;
  
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: string
                                                                         attributes: _terminalProtocolHandler.textAttributes];

  [_incomingLineBuffer appendAttributedString: attributedString];
}

- (void) displayBufferedStringAsPrompt
{
  [self.state.codebaseAnalyzer notePrompt: _incomingLineBuffer];

  [self.delegate displayAttributedStringAsPrompt: [_filterQueue processPartialLine: _incomingLineBuffer]];
  [_incomingLineBuffer deleteCharactersInRange: NSMakeRange (0, _incomingLineBuffer.length)];
}

- (void) displayBufferedStringAsText
{
  if (_incomingLineBuffer && _incomingLineBuffer.length > 0)
  {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([_recentReceivedStrings containsObject: _incomingLineBuffer.string]
        && ![_incomingLineBuffer.string isEqualToString: @"\n"])             // Exclude blank lines from filtering.
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
      
      [_recentReceivedStrings addObject: [_incomingLineBuffer.string copy]];
    }
    
    if (_clearRecentReceivedStringTimer.isValid)
      [_clearRecentReceivedStringTimer invalidate];
    
    _clearRecentReceivedStringTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                                       target: self
                                                                     selector: @selector (_clearRecentReceivedStrings:)
                                                                     userInfo: nil
                                                                      repeats: NO];
    
    [self.state.codebaseAnalyzer noteTextString: _incomingLineBuffer];

    [self.delegate displayAttributedString: [_filterQueue processCompleteLine: _incomingLineBuffer]];
    [_incomingLineBuffer deleteCharactersInRange: NSMakeRange (0, _incomingLineBuffer.length)];
  }
}

- (void) maybeDisplayBufferedStringAsPrompt
{
  if (!_incomingLineBuffer || _incomingLineBuffer.length == 0
      || self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH) // TinyMUSH does not use prompts.
    return;                                                                      // PennMUSH does, though.

  // This is a heuristic. I've made it fairly tight to avoid false positives.

  if (self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyDikuMUD
      || self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyGenericMUD)
  {
    // MUDs are held to a less-tight restriction - they don't need a space for their prompts. (We will add the space if
    // the MUD leaves it out.)
    //
    // Also, MUD prompts can end in '!' or '.' as well as promptier characters.

    NSString *promptCandidate = _incomingLineBuffer.string;

    while ([promptCandidate hasSuffix: @" "])
      promptCandidate = [promptCandidate substringToIndex: promptCandidate.length - 1];

    NSCharacterSet *promptCharacterSet = [NSCharacterSet characterSetWithCharactersInString: @">?|:)]."];

    if ([promptCharacterSet characterIsMember: [promptCandidate characterAtIndex: promptCandidate.length - 1]])
    {
      if (![_incomingLineBuffer.string hasSuffix: @" "])
        [self appendStringToLineBuffer: @" "];

      [self displayBufferedStringAsPrompt];
    }
  }
  else if ([_incomingLineBuffer.string hasSuffix: @" "])
  {
    NSString *promptCandidate = _incomingLineBuffer.string;

    while ([promptCandidate hasSuffix: @" "])
      promptCandidate = [promptCandidate substringToIndex: promptCandidate.length - 1];

    NSCharacterSet *promptCharacterSet = [NSCharacterSet characterSetWithCharactersInString: @">?|:)]"];

    if ([promptCharacterSet characterIsMember: [promptCandidate characterAtIndex: promptCandidate.length - 1]])
      [self displayBufferedStringAsPrompt];
  }
}

- (void) writeDataToSocket: (NSData *) data
{
  [_outgoingDataBuffer appendData: data];
  
  if (_outputStreamHasSpaceAvailable)
    [self _writeBufferedDataToOutputStream];
}

#pragma mark - MUTelnetProtocolHandlerDelegate protocol

- (void) enableTLS
{
  NSDictionary *sslSettings = @{(NSString *) kCFStreamSSLAllowsExpiredCertificates: @YES,
                                (NSString *) kCFStreamSSLAllowsExpiredRoots: @YES,
                                (NSString *) kCFStreamSSLAllowsAnyRoot: @YES,
                                (NSString *) kCFStreamSSLValidatesCertificateChain: @NO,
                                (NSString *) kCFStreamSSLPeerName: _profile.world.hostname,
                                (NSString *) kCFStreamSSLLevel: (NSString *) kCFStreamSocketSecurityLevelNegotiatedSSL};
  
  CFReadStreamSetProperty ((CFReadStreamRef) _inputStream, kCFStreamPropertySSLSettings, (CFTypeRef) sslSettings);
  CFWriteStreamSetProperty ((CFWriteStreamRef) _outputStream, kCFStreamPropertySSLSettings, (CFTypeRef) sslSettings);
}

- (void) reportWindowSizeToServer
{
  [self.delegate reportWindowSizeToServer];
}

- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  if (_lastNumberOfLines == numberOfLines && _lastNumberOfColumns == numberOfColumns)
    return;

  _lastNumberOfColumns = numberOfColumns;
  _lastNumberOfLines = numberOfLines;

  [_telnetProtocolHandler sendNAWSSubnegotiationWithNumberOfLines: numberOfLines columns: numberOfColumns];
}

#pragma mark - Private methods

- (void) _attemptReconnect
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ([defaults boolForKey: MUPAutomaticReconnect]
      && ++_reconnectCount < (NSUInteger) [defaults integerForKey: MUPAutomaticReconnectCount]
      && !([_lastSentLine.lowercaseString rangeOfString: @"quit"].location != NSNotFound
           || [_lastSentLine.lowercaseString rangeOfString: @"@shutdown"].location != NSNotFound
           || [_lastSentLine isEqualToString: @"0"])) // Used as 'logout' on DikuMUDs and possibly others.
    [self open];
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

- (void) _registerObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver: object
                         selector: @selector (MUDConnectionDidConnect:)
                             name: MUMUDConnectionDidConnectNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (MUDConnectionIsConnecting:)
                             name: MUMUDConnectionIsConnectingNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (MUDConnectionWasClosedByClient:)
                             name: MUMUDConnectionWasClosedByClientNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (MUDConnectionWasClosedByServer:)
                             name: MUMUDConnectionWasClosedByServerNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (MUDConnectionWasClosedWithError:)
                             name: MUMUDConnectionWasClosedWithErrorNotification
                           object: self];
}

- (void) _reset
{
  [_inputStream close];
  [_outputStream close];

  [_inputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_outputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];

  _inputStream = nil;
  _outputStream = nil;
  _outputStreamHasSpaceAvailable = NO;

  [_state reset];
  [_protocolStack reset];

  [_recentReceivedStrings removeAllObjects];
  [_clearRecentReceivedStringTimer invalidate];
  _clearRecentReceivedStringTimer = nil;
  
  _dateConnected = nil;

  _lastNumberOfColumns = 0;
  _lastNumberOfLines = 0;
}

- (void) _sendPeriodicPing: (NSTimer *) pingTimer
{
  if (self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyPennMUSH
      || self.state.codebaseAnalyzer.codebase == MUCodebaseRhostMUSH)
    [self writeLine: @"IDLE"];
  else if (self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH)
    [self writeLine: @"@@"];
  else if (self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyEvennia)
    [self writeLine: @"idle"];
}

- (void) _unregisterObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter removeObserver: object name: MUMUDConnectionDidConnectNotification object: self];
  [notificationCenter removeObserver: object name: MUMUDConnectionIsConnectingNotification object: self];
  [notificationCenter removeObserver: object name: MUMUDConnectionWasClosedByClientNotification object: self];
  [notificationCenter removeObserver: object name: MUMUDConnectionWasClosedByServerNotification object: self];
  [notificationCenter removeObserver: object name: MUMUDConnectionWasClosedWithErrorNotification object: self];
}

- (void) _writeBufferedDataToOutputStream
{
  uint8_t *bytes = (uint8_t *) [_outgoingDataBuffer mutableBytes];
  NSInteger bytesWritten = [_outputStream write: (const uint8_t *) bytes maxLength: _outgoingDataBuffer.length];
  if (bytesWritten < 0)
  {
    // FIXME: Error condition. Is this the correct way to handle this?
    _outputStreamHasSpaceAvailable = NO;
    return;
  }
  [_outgoingDataBuffer replaceBytesInRange: NSMakeRange (0, bytesWritten) withBytes: NULL length: 0];
  _outputStreamHasSpaceAvailable = NO;
}

- (void) _writeDataWithPreprocessing: (NSData *) data
{
  [_protocolStack preprocessOutputData: data];
}

@end
