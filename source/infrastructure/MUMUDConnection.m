//
// MUMUDConnection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnection.h"
#import "MUAbstractConnectionSubclass.h"

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
  MUSocketFactory *_socketFactory;

  MUWorld *_world;
  NSTimer *_pollTimer;
}

+ (id) connectionWithWorld: (MUWorld *) world
                  delegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [[self alloc] initWithWorld: world delegate: delegate];
}

- (id) initWithWorld: (MUWorld *) world
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
  _world = world;
  _pollTimer = nil;
  
  _protocolStack = [[MUProtocolStack alloc] initWithConnectionState: _state];
  [_protocolStack setDelegate: self];
  
  // Ordering is important for byte protocol handlers: they should be added in
  // order with respect to outgoing data, and reverse order with respect to
  // incoming data.
  
  MUMCPProtocolHandler *mcpProtocolHandler = [MUMCPProtocolHandler protocolHandlerWithConnectionState: _state];
  mcpProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: mcpProtocolHandler];

  MUTerminalProtocolHandler *terminalProtocolHandler = [MUTerminalProtocolHandler protocolHandlerWithConnectionState: _state];
  terminalProtocolHandler.delegate = self;
  [_protocolStack addProtocolHandler: terminalProtocolHandler];
  
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
  [self _unregisterObjectForNotifications: _delegate];
  _delegate = nil;
  
  [self close];
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
                                      (__bridge CFStringRef) _world.hostname,
                                      (UInt32) _world.port.integerValue,
                                      &readStream,
                                      &writeStream);
  
  _inputStream = (__bridge_transfer NSInputStream *) readStream;
  _outputStream = (__bridge_transfer NSOutputStream *) writeStream;
  
  _inputStream.delegate = self;
  _outputStream.delegate = self;
  
  if (_world.forceTLS)
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

#pragma mark - Various delegates

- (void) log: (NSString *) message arguments: (va_list) args
{
  NSLog (@"[%@:%@] %@", _world.hostname, _world.port, [[NSString alloc] initWithFormat: message arguments: args]);
}

#pragma mark - NSStreamDelegate

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
        unsigned numberOfBytesToRead = _state.needsSingleByteSocketReads ? 1 : 1;
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

#pragma mark - MUProtocolStackDelegate

- (void) displayAttributedStringAsText: (NSAttributedString *) attributedString
{
  [self.state.codebaseAnalyzer noteTextString: attributedString];
  
  [self.delegate displayAttributedString: attributedString];
}

- (void) displayAttributedStringAsPrompt: (NSAttributedString *) attributedString
{
  [self.state.codebaseAnalyzer notePrompt: attributedString];
  
  [self.delegate displayAttributedStringAsPrompt: attributedString];
}

- (void) writeDataToSocket: (NSData *) data
{
  [_outgoingDataBuffer appendData: data];
  
  if (_outputStreamHasSpaceAvailable)
    [self _writeBufferedDataToOutputStream];
}

#pragma mark - MUTelnetProtocolHandlerDelegate

- (void) enableTLS
{
  NSDictionary *sslSettings = @{(NSString *) kCFStreamSSLAllowsExpiredCertificates: @YES,
                                (NSString *) kCFStreamSSLAllowsExpiredRoots: @YES,
                                (NSString *) kCFStreamSSLAllowsAnyRoot: @YES,
                                (NSString *) kCFStreamSSLValidatesCertificateChain: @NO,
                                (NSString *) kCFStreamSSLPeerName: _world.hostname,
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
