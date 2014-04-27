//
// MUMUDConnection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnection.h"
#import "MUAbstractConnectionSubclass.h"

#import "NSFont+Traits.h"

NSString *MUMUDConnectionDidConnectNotification = @"MUMUDConnectionDidConnectNotification";
NSString *MUMUDConnectionIsConnectingNotification = @"MUMUDConnectionIsConnectingNotification";
NSString *MUMUDConnectionWasClosedByClientNotification = @"MUMUDConnectionWasClosedByClientNotification";
NSString *MUMUDConnectionWasClosedByServerNotification = @"MUMUDConnectionWasClosedByServerNotification";
NSString *MUMUDConnectionWasClosedWithErrorNotification = @"MUMUDConnectionWasClosedWithErrorNotification";
NSString *MUMUDConnectionErrorKey = @"MUMUDConnectionErrorKey";

@interface MUMUDConnection ()

- (void) _cleanUpStreams;
- (void) _registerObjectForNotifications: (id) object;
- (void) _resetState;
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

  MUProtocolStack *_protocolStack;
  MUTelnetProtocolHandler *_telnetProtocolHandler;
  MUTerminalProtocolHandler *_terminalProtocolHandler;

  MUProfile *_profile;
  NSTimer *_pollTimer;

  NSUInteger _lastWindowColumns;
  NSUInteger _lastWindowLines;

  NSMutableAttributedString *_attributedLineBuffer;
}

+ (id) connectionWithProfile: (MUProfile *) profile
                    delegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [[self alloc] initWithProfile: profile delegate: delegate];
}

- (id) initWithProfile: (MUProfile *) profile
              delegate: (NSObject <MUMUDConnectionDelegate> *) newDelegate;
{
  if (!(self = [super init]))
    return nil;
  
  _inputStream = nil;
  _outputStream = nil;
  _outputStreamHasSpaceAvailable = NO;
  
  _outgoingDataBuffer = [NSMutableData dataWithCapacity: 2048];
  
  _state = [[MUMUDConnectionState alloc] initWithCodebaseAnalyzerDelegate: self];
  _dateConnected = nil;
  _profile = profile;
  _pollTimer = nil;

  _lastWindowColumns = 0;
  _lastWindowLines = 0;

  _attributedLineBuffer = [[NSMutableAttributedString alloc] init];
  
  _protocolStack = [[MUProtocolStack alloc] initWithConnectionState: _state];
  [_protocolStack setDelegate: self];
  
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
  
  _delegate = newDelegate;
  if (_delegate)
    [self _registerObjectForNotifications: _delegate];
  
  return self;
}

- (void) dealloc
{
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

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  [self log: message arguments: args];
  
  va_end (args);
}

- (void) writeLine: (NSString *) line
{
  NSString *lineWithLineEnding = [NSString stringWithFormat: @"%@\r\n", line];
  NSData *encodedData = [lineWithLineEnding dataUsingEncoding: self.state.stringEncoding allowLossyConversion: YES];
  [self _writeDataWithPreprocessing: encodedData];
}

#pragma mark - MUAbstractConnection overrides

- (void) close
{
  if (self.isConnectedOrConnecting)
  {
    [self _cleanUpStreams];
    [self setStatusClosedByClient];
  }
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
  
  _dateConnected = nil;
  [self _resetState];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByClientNotification
                                                      object: self];
}

- (void) setStatusClosedByServer
{
  [super setStatusClosedByServer];
  
  _dateConnected = nil;
  [self _resetState];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByServerNotification
                                                      object: self];
}

- (void) setStatusClosedWithError: (NSError *) error
{
  [super setStatusClosedWithError: error];
  
  _dateConnected = nil;
  [self _resetState];
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedWithErrorNotification
                                                      object: self
                                                    userInfo: @{MUMUDConnectionErrorKey: error}];
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
        [self _cleanUpStreams];
        [self setStatusClosedByServer];
      }
      return;
      
    case NSStreamEventErrorOccurred:
      [self _cleanUpStreams];
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
          [self _cleanUpStreams];
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
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: string
                                                                         attributes: _terminalProtocolHandler.textAttributes];
  [_attributedLineBuffer appendAttributedString: attributedString];
}

- (void) displayBufferedStringAsText
{
  [self.state.codebaseAnalyzer noteTextString: _attributedLineBuffer];
  [self.delegate displayAttributedString: _attributedLineBuffer];
  [_attributedLineBuffer deleteCharactersInRange: NSMakeRange (0, _attributedLineBuffer.length)];
}

- (void) displayBufferedStringAsPrompt
{
  [self.state.codebaseAnalyzer notePrompt: _attributedLineBuffer];
  [self.delegate displayAttributedStringAsPrompt: _attributedLineBuffer];
  [_attributedLineBuffer deleteCharactersInRange: NSMakeRange (0, _attributedLineBuffer.length)];
}

- (void) maybeDisplayBufferedStringAsPrompt
{
  if (self.state.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH) // TinyMUSH does not use prompts.
    return;                                                                         // PennMUSH does, though.

  // This is a heuristic. I've made it as tight as I can to avoid false positives.

  if ([_attributedLineBuffer.string hasSuffix: @" "])
  {
    NSString *promptCandidate = [_attributedLineBuffer.string substringToIndex: _attributedLineBuffer.length - 1];

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
  if (_lastWindowLines == numberOfLines && _lastWindowColumns == numberOfColumns)
    return;

  _lastWindowColumns = numberOfColumns;
  _lastWindowLines = numberOfLines;

  [_telnetProtocolHandler sendNAWSSubnegotiationWithNumberOfLines: numberOfLines columns: numberOfColumns];
}

#pragma mark - Private methods

- (void) _cleanUpStreams
{
  [_inputStream close];
  [_outputStream close];
  
  [_inputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  [_outputStream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
  
  _inputStream = nil;
  _outputStream = nil;
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

- (void) _resetState
{
  [_state reset];
  [_telnetProtocolHandler reset];
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
