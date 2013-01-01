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

- (void) cleanUpPollTimer;
- (void) displayAndLogString: (NSString *) string;
- (void) fireTimer: (NSTimer *) timer;
- (void) initializeSocket;
- (BOOL) isUsingSocket: (MUSocket *) possibleSocket;
- (void) poll;
- (void) registerObjectForNotifications: (id) object;
- (void) schedulePollTimer;
- (void) unregisterObjectForNotifications: (id) object;
- (void) writeDataWithPreprocessing: (NSData *) data;

@end

#pragma mark -

@implementation MUMUDConnection

@synthesize delegate = _delegate;
@synthesize socket, state;

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
  
  state = [MUMUDConnectionState connectionState];
  socketFactory = factory;
  hostname = [newHostname copy];
  port = newPort;
  pollTimer = nil;
  
  protocolStack = [[MUProtocolStack alloc] initWithConnectionState: state];
  [protocolStack setDelegate: self];
  
  // Ordering is important for byte protocol handlers: they should be added in
  // order with respect to outgoing data, and reverse order with respect to
  // incoming data.
  
  MUMCPProtocolHandler *mcpProtocolHandler = [MUMCPProtocolHandler protocolHandlerWithConnectionState: state];
  [mcpProtocolHandler setDelegate: self];
  [protocolStack addProtocolHandler: mcpProtocolHandler];
  
  MUTelnetProtocolHandler *telnetProtocolHandler = [MUTelnetProtocolHandler protocolHandlerWithConnectionState: state];
  [telnetProtocolHandler setDelegate: self];
  [protocolStack addProtocolHandler: telnetProtocolHandler];
  
  MUMCCPProtocolHandler *mccpProtocolHandler = [MUMCCPProtocolHandler protocolHandlerWithConnectionState: state];
  [mccpProtocolHandler setDelegate: self];
  [protocolStack addProtocolHandler: mccpProtocolHandler];
  
  _delegate = newDelegate;
  if (_delegate)
    [self registerObjectForNotifications: _delegate];
  
  return self;
}

- (void) dealloc
{
  [self unregisterObjectForNotifications: _delegate];
  _delegate = nil;
  
  [self close];
  [self cleanUpPollTimer];
  
}

- (void) setDelegate: (NSObject <MUMUDConnectionDelegate> *) object
{
  if (_delegate == object)
    return;
  
  [self unregisterObjectForNotifications: _delegate];
  [self registerObjectForNotifications: object];
  
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
  [self writeDataWithPreprocessing: encodedData];
}

#pragma mark - MUAbstractConnection overrides

- (void) close
{
  [self.socket close];
}

- (void) open
{
  [self initializeSocket];
  [self schedulePollTimer];
  [self.socket open];
}

- (void) setStatusConnected
{
  [super setStatusConnected];
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
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByClientNotification
                                                      object: self];
}

- (void) setStatusClosedByServer
{
  [super setStatusClosedByServer];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByServerNotification
                                                      object: self];
}

- (void) setStatusClosedWithError: (NSString *) error
{
  [super setStatusClosedWithError: error];
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
  [self cleanUpPollTimer]; 
  [self setStatusClosedByClient];
}

- (void) socketWasClosedByServer: (NSNotification *) notification
{
  [self.state reset];
  [self cleanUpPollTimer];
  [self setStatusClosedByServer];
}

- (void) socketWasClosedWithError: (NSNotification *) notification
{
  [self.state reset];
  [self cleanUpPollTimer];
  [self setStatusClosedWithError: [notification.userInfo valueForKey: MUSocketErrorMessageKey]];
}

#pragma mark - Various delegates

- (void) log: (NSString *) message arguments: (va_list) args
{
  NSLog (@"[%@:%d] %@", hostname, port, [[NSString alloc] initWithFormat: message arguments: args]);
}

#pragma mark - MUProtocolStackDelegate

- (void) displayDataAsText: (NSData *) parsedData
{
  NSString *parsedString = [[NSString alloc] initWithBytes: parsedData.bytes
                                                    length: parsedData.length
                                                  encoding: self.state.stringEncoding];
  
  if (self.state.stringEncoding == NSASCIIStringEncoding)
    parsedString = [parsedString stringWithCodePage437Substitutions];
  
  [self.delegate displayString: parsedString];
}

- (void) displayDataAsPrompt: (NSData *) parsedData
{
  NSString *parsedPromptString = [[NSString alloc] initWithBytes: parsedData.bytes
                                                          length: parsedData.length
                                                        encoding: self.state.stringEncoding];
  
  if (self.state.stringEncoding == NSASCIIStringEncoding)
    parsedPromptString = [parsedPromptString stringWithCodePage437Substitutions];
  
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
  if (!state.shouldReportWindowSizeChanges)
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

- (void) cleanUpPollTimer
{
  [pollTimer invalidate];
  pollTimer = nil;
}

- (void) displayAndLogString: (NSString *) string
{
  [self.delegate displayString: [NSString stringWithFormat: @"%@\n", string]];
  [self log: @"%@", string];
}

- (void) fireTimer: (NSTimer *) timer
{
  [self poll];
}

- (void) initializeSocket
{
  self.socket = [socketFactory makeSocketWithHostname: hostname port: port];
  self.socket.delegate = self;
}

- (BOOL) isUsingSocket: (MUSocket *) possibleSocket
{
  return possibleSocket == self.socket;
}

- (void) poll
{
  // It is possible for the connection to have been released but for there to
  // be a pending timer fire that was registered before the timers were
  // invalidated.
  
  if (!self.socket || !self.socket.isConnected)
    return;
  
  [self.socket poll];
  
  if (self.socket.hasDataAvailable)
    [protocolStack parseInputData: [self.socket readUpToLength: self.socket.availableBytes]];
}

- (void) registerObjectForNotifications: (id) object
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

- (void) schedulePollTimer
{
  pollTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05
                                               target: self
                                             selector: @selector (fireTimer:)
                                             userInfo: nil
                                              repeats: YES];
}

- (void) unregisterObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter removeObserver: object name: MUSocketDidConnectNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketIsConnectingNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedByClientNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedByServerNotification object: self];
  [notificationCenter removeObserver: object name: MUSocketWasClosedWithErrorNotification object: self];
}

- (void) writeDataWithPreprocessing: (NSData *) data
{
  [protocolStack preprocessOutputData: data];
}

@end
