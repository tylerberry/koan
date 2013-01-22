//
// MUMUDConnection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnection.h"
#import "MUAbstractConnectionSubclass.h"

#import "MUSocketFactory.h"
#import "MUSocket.h"

#import "MUMCPProtocolHandler.h"
#import "MUMCCPProtocolHandler.h"
#import "MUTelnetProtocolHandler.h"

#import "NSString (CodePage437).h"

NSString *MUMUDConnectionDidConnectNotification = @"MUMUDConnectionDidConnectNotification";
NSString *MUMUDConnectionIsConnectingNotification = @"MUMUDConnectionIsConnectingNotification";
NSString *MUMUDConnectionWasClosedByClientNotification = @"MUMUDConnectionWasClosedByClientNotification";
NSString *MUMUDConnectionWasClosedByServerNotification = @"MUMUDConnectionWasClosedByServerNotification";
NSString *MUMUDConnectionWasClosedWithErrorNotification = @"MUMUDConnectionWasClosedWithErrorNotification";
NSString *MUMUDConnectionErrorMessageKey = @"MUMUDConnectionErrorMessageKey";

@interface MUMUDConnection ()
{
  MUProtocolStack *_protocolStack;
  MUSocketFactory *_socketFactory;
  
  NSString *_hostname;
  int _port;
  NSTimer *_pollTimer;
}

@property (strong, nonatomic) MUSocket *socket;

- (void) _cleanUpPollTimer;
- (void) _displayAndLogString: (NSString *) string;
- (void) _fireTimer: (NSTimer *) timer;
- (void) _initializeSocket;
- (BOOL) _isUsingSocket: (MUSocket *) possibleSocket;
- (void) _poll;
- (void) _registerObjectForNotifications: (id) object;
- (void) _schedulePollTimer;
- (void) _unregisterObjectForNotifications: (id) object;
- (void) _writeDataWithPreprocessing: (NSData *) data;

@end

#pragma mark -

@implementation MUMUDConnection

+ (id) telnetWithSocketFactory: (MUSocketFactory *) factory
                      hostname: (NSString *) hostname
                          port: (int) port
                      delegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [[self alloc] initWithSocketFactory: factory hostname: hostname port: port delegate: delegate];
}

+ (id) telnetWithHostname: (NSString *) hostname
                     port: (int) port
                 delegate: (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return [self telnetWithSocketFactory: [MUSocketFactory defaultFactory] hostname: hostname port: port delegate: delegate];
}

- (id) initWithSocketFactory: (MUSocketFactory *) factory
                    hostname: (NSString *) newHostname
                        port: (int) newPort
                    delegate: (NSObject <MUMUDConnectionDelegate> *) newDelegate;
{
  if (!(self = [super init]))
    return nil;
  
  _state = [[MUMUDConnectionState alloc] initWithCodebaseAnalyzerDelegate: self];
  _dateConnected = nil;
  _socketFactory = factory;
  _hostname = [newHostname copy];
  _port = newPort;
  _pollTimer = nil;
  
  _protocolStack = [[MUProtocolStack alloc] initWithConnectionState: _state];
  [_protocolStack setDelegate: self];
  
  // Ordering is important for byte protocol handlers: they should be added in
  // order with respect to outgoing data, and reverse order with respect to
  // incoming data.
  
  MUMCPProtocolHandler *mcpProtocolHandler = [MUMCPProtocolHandler protocolHandlerWithConnectionState: _state];
  [mcpProtocolHandler setDelegate: self];
  [_protocolStack addProtocolHandler: mcpProtocolHandler];
  
  MUTelnetProtocolHandler *telnetProtocolHandler = [MUTelnetProtocolHandler protocolHandlerWithConnectionState: _state];
  [telnetProtocolHandler setDelegate: self];
  [_protocolStack addProtocolHandler: telnetProtocolHandler];
  
  MUMCCPProtocolHandler *mccpProtocolHandler = [MUMCCPProtocolHandler protocolHandlerWithConnectionState: _state];
  [mccpProtocolHandler setDelegate: self];
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
  [self _cleanUpPollTimer];
  
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
  NSString *lineWithLineEnding = [NSString stringWithFormat: @"%@\r\n",line];
  NSData *encodedData = [lineWithLineEnding dataUsingEncoding: self.state.stringEncoding allowLossyConversion: YES];
  [self _writeDataWithPreprocessing: encodedData];
}

#pragma mark - MUAbstractConnection overrides

- (void) close
{
  [self.socket close];
}

- (void) open
{
  [self _initializeSocket];
  [self _schedulePollTimer];
  [self.socket open];
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
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByClientNotification
                                                      object: self];
}

- (void) setStatusClosedByServer
{
  [super setStatusClosedByServer];
  
  _dateConnected = nil;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByServerNotification
                                                      object: self];
}

- (void) setStatusClosedWithError: (NSString *) error
{
  [super setStatusClosedWithError: error];
  
  _dateConnected = nil;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedWithErrorNotification
                                                      object: self
                                                    userInfo: @{MUMUDConnectionErrorMessageKey: error}];
}

#pragma mark - MUSocketDelegate protocol

- (void) socketIsConnecting: (NSNotification *) notification
{
  [self setStatusConnecting];
}

- (void) socketDidConnect: (NSNotification *) notification
{
  [self setStatusConnected];
}

- (void) socketWasClosedByClient: (NSNotification *) notification
{
  [self.state reset];
  [self _cleanUpPollTimer];
  [self setStatusClosedByClient];
}

- (void) socketWasClosedByServer: (NSNotification *) notification
{
  [self.state reset];
  [self _cleanUpPollTimer];
  [self setStatusClosedByServer];
}

- (void) socketWasClosedWithError: (NSNotification *) notification
{
  [self.state reset];
  [self _cleanUpPollTimer];
  [self setStatusClosedWithError: [notification.userInfo valueForKey: MUSocketErrorMessageKey]];
}

#pragma mark - Various delegates

- (void) log: (NSString *) message arguments: (va_list) args
{
  NSLog (@"[%@:%d] %@", _hostname, _port, [[NSString alloc] initWithFormat: message arguments: args]);
}

#pragma mark - MUProtocolStackDelegate

- (void) displayDataAsText: (NSData *) parsedData
{
  NSString *parsedString = [[NSString alloc] initWithBytes: parsedData.bytes
                                                    length: parsedData.length
                                                  encoding: self.state.stringEncoding];
  
  // This is a pseudo-encoding: if we are using ASCII, substitute in CP437 characters. 8BitMUSH for life!
  
  if (self.state.stringEncoding == NSASCIIStringEncoding)
    parsedString = [parsedString stringWithCodePage437Substitutions];
  
  [self.state.codebaseAnalyzer noteTextLine: parsedString];
  
  [self.delegate displayString: parsedString];
}

- (void) displayDataAsPrompt: (NSData *) parsedData
{
  NSString *parsedPromptString = [[NSString alloc] initWithBytes: parsedData.bytes
                                                          length: parsedData.length
                                                        encoding: self.state.stringEncoding];
  
  if (self.state.stringEncoding == NSASCIIStringEncoding)
    parsedPromptString = [parsedPromptString stringWithCodePage437Substitutions];
  
  [self.state.codebaseAnalyzer notePrompt: parsedPromptString];
  
  [self.delegate displayPrompt: parsedPromptString];
}

- (void) writeDataToSocket: (NSData *) data
{
  [self.socket write: data];
}

#pragma mark - MUTelnetProtocolHandlerDelegate

- (void) reportWindowSizeToServer
{
  [self.delegate reportWindowSizeToServer];
}

- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  if (!_state.shouldReportWindowSizeChanges)
    return;
  
  uint8_t nawsSubnegotiationHeader[3] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionNegotiateAboutWindowSize};
  uint8_t nawsSubnegotiationFooter[2] = {MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  NSMutableData *constructedData = [NSMutableData dataWithBytes: nawsSubnegotiationHeader length: 3];
  
  uint8_t width1 = numberOfColumns / 255;
  uint8_t width0 = numberOfColumns % 255;
  uint8_t height1 = numberOfLines / 255;
  uint8_t height0 = numberOfLines % 255;
  
  [constructedData appendBytes: &width1 length: 1];
  if (width1 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &width1 length: 1];
    
  [constructedData appendBytes: &width0 length: 1];
  if (width0 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &width0 length: 1];
  
  [constructedData appendBytes: &height1 length: 1];
  if (height1 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &height1 length: 1];
  
  [constructedData appendBytes: &height0 length: 1];
  if (height0 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &height0 length: 1];
  
  [constructedData appendBytes: nawsSubnegotiationFooter length: 2];
  
  [self writeDataToSocket: constructedData];
  [self log: @"    Sent: IAC SB %@ %d %d %d %d IAC SE.",
   [MUTelnetOption optionNameForByte: MUTelnetOptionNegotiateAboutWindowSize], width1, width0, height1, height0];
}

#pragma mark - Private methods

- (void) _cleanUpPollTimer
{
  [_pollTimer invalidate];
  _pollTimer = nil;
}

- (void) _displayAndLogString: (NSString *) string
{
  [self.delegate displayString: [NSString stringWithFormat: @"%@\n", string]];
  [self log: @"%@", string];
}

- (void) _fireTimer: (NSTimer *) timer
{
  [self _poll];
}

- (void) _initializeSocket
{
  self.socket = [_socketFactory makeSocketWithHostname: _hostname port: _port];
  self.socket.delegate = self;
}

- (BOOL) _isUsingSocket: (MUSocket *) possibleSocket
{
  return possibleSocket == self.socket;
}

- (void) _poll
{
  // It is possible for the connection to have been released but for there to
  // be a pending timer fire that was registered before the timers were
  // invalidated.
  
  if (!self.socket || !self.socket.isConnected)
    return;
  
  [self.socket poll];
  
  if (self.socket.hasDataAvailable)
    [_protocolStack parseInputData: [self.socket readUpToLength: self.socket.availableBytes]];
}

- (void) _registerObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver: object
                         selector: @selector (telnetConnectionDidConnect:)
                             name: MUMUDConnectionDidConnectNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (telnetConnectionIsConnecting:)
                             name: MUMUDConnectionIsConnectingNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (telnetConnectionWasClosedByClient:)
                             name: MUMUDConnectionWasClosedByClientNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (telnetConnectionWasClosedByServer:)
                             name: MUMUDConnectionWasClosedByServerNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector (telnetConnectionWasClosedWithError:)
                             name: MUMUDConnectionWasClosedWithErrorNotification
                           object: self];
}

- (void) _schedulePollTimer
{
  _pollTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05
                                                target: self
                                              selector: @selector (_fireTimer:)
                                              userInfo: nil
                                               repeats: YES];
}

- (void) _unregisterObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter removeObserver: object name: MUSocketDidConnectNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketIsConnectingNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedByClientNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedByServerNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedWithErrorNotification object: self];
}

- (void) _writeDataWithPreprocessing: (NSData *) data
{
  [_protocolStack preprocessOutputData: data];
}

@end
