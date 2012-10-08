//
// MUMUDConnection.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUMUDConnection.h"
#import "MUAbstractConnectionSubclass.h"

#import "MUSocketFactory.h"
#import "MUSocket.h"

#import "MUMCPProtocolHandler.h"
#import "MUMCCPProtocolHandler.h"
#import "MUTelnetProtocolHandler.h"

NSString *MUMUDConnectionDidConnectNotification = @"MUMUDConnectionDidConnectNotification";
NSString *MUMUDConnectionIsConnectingNotification = @"MUMUDConnectionIsConnectingNotification";
NSString *MUMUDConnectionWasClosedByClientNotification = @"MUMUDConnectionWasClosedByClientNotification";
NSString *MUMUDConnectionWasClosedByServerNotification = @"MUMUDConnectionWasClosedByServerNotification";
NSString *MUMUDConnectionWasClosedWithErrorNotification = @"MUMUDConnectionWasClosedWithErrorNotification";
NSString *MUMUDConnectionErrorMessageKey = @"MUMUDConnectionErrorMessageKey";

@interface MUMUDConnection (Private)

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
  
  MUMCPProtocolHandler *mcpProtocolHandler = [MUMCPProtocolHandler protocolHandlerWithStack: protocolStack connectionState: state];
  [mcpProtocolHandler setDelegate: self];
  [protocolStack addByteProtocol: mcpProtocolHandler];
  
  MUTelnetProtocolHandler *telnetProtocolHandler = [MUTelnetProtocolHandler protocolHandlerWithStack: protocolStack connectionState: state];
  [telnetProtocolHandler setDelegate: self];
  [protocolStack addByteProtocol: telnetProtocolHandler];
  
  MUMCCPProtocolHandler *mccpProtocolHandler = [MUMCCPProtocolHandler protocolHandlerWithStack: protocolStack connectionState: state];
  [mccpProtocolHandler setDelegate: self];
  [protocolStack addByteProtocol: mccpProtocolHandler];
  
  delegate = newDelegate;
  return self;
}

- (void) dealloc
{
  [self unregisterObjectForNotifications: delegate];
  delegate = nil;
  
  [self close];
  [self cleanUpPollTimer];
  
}

- (NSObject <MUMUDConnectionDelegate> *) delegate
{
  return delegate;
}

- (void) setDelegate: (NSObject <MUMUDConnectionDelegate> *) object
{
  if (delegate == object)
    return;
  
  [self unregisterObjectForNotifications: delegate];
  [self registerObjectForNotifications: object];
  
  delegate = object;
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
  [self displayAndLogString: @"Connected to server."];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionDidConnectNotification
                                                      object: self];
}

- (void) setStatusConnecting
{
  [super setStatusConnecting];
  [self.delegate displayString: @"Connecting...\n"];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionIsConnectingNotification
                                                      object: self];
}

- (void) setStatusClosedByClient
{
  [super setStatusClosedByClient];
  [self displayAndLogString: @"Connection closed by client."];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByClientNotification
                                                      object: self];
}

- (void) setStatusClosedByServer
{
  [super setStatusClosedByServer];
  [self displayAndLogString: @"Connection closed by server."];
  [[NSNotificationCenter defaultCenter] postNotificationName: MUMUDConnectionWasClosedByServerNotification
                                                      object: self];
}

- (void) setStatusClosedWithError: (NSString *) error
{
  [super setStatusClosedWithError: error];
  [self displayAndLogString: [NSString stringWithFormat: @"Connection closed with error: %@.", error]];
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
  [self cleanUpPollTimer]; 
  [self setStatusClosedByClient];
}

- (void) socketWasClosedByServer: (NSNotification *) notification
{
  [self cleanUpPollTimer];
  [self setStatusClosedByServer];
}

- (void) socketWasClosedWithError: (NSNotification *) notification
{
  [self cleanUpPollTimer];
  [self setStatusClosedWithError: [[notification userInfo] valueForKey: MUSocketErrorMessageKey]];
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
  
  [self.delegate displayString: parsedString];
}

- (void) displayDataAsPrompt: (NSData *) parsedData
{
  NSString *parsedPromptString = [[NSString alloc] initWithBytes: parsedData.bytes
                                                          length: parsedData.length
                                                        encoding: self.state.stringEncoding];
  
  [self.delegate displayPrompt: parsedPromptString];
}

#pragma mark - MUTelnetProtocolHandlerDelegate

- (void) reportWindowSizeToServer
{
  [delegate reportWindowSizeToServer];
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

- (void) writeDataToSocket: (NSData *) data
{
  [self.socket write: data];
}

@end

#pragma mark -

@implementation MUMUDConnection (Private)

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
  if (!self.socket || ![self.socket isConnected])
    return;
  
  [self.socket poll];
  
  if ([self.socket hasDataAvailable])
    [protocolStack parseInputData: [self.socket readUpToLength: [self.socket availableBytes]]];
}

- (void) registerObjectForNotifications: (id) object
{
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver: object
                         selector: @selector(telnetConnectionDidConnect:)
                             name: MUMUDConnectionDidConnectNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector(telnetConnectionIsConnecting:)
                             name: MUMUDConnectionIsConnectingNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector(telnetConnectionWasClosedByClient:)
                             name: MUMUDConnectionWasClosedByClientNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector(telnetConnectionWasClosedByServer:)
                             name: MUMUDConnectionWasClosedByServerNotification
                           object: self];
  [notificationCenter addObserver: object
                         selector: @selector(telnetConnectionWasClosedWithError:)
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
  [self writeDataToSocket: [protocolStack preprocessOutputData: data]];
}

@end
