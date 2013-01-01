//
// MUMUDConnection.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUByteDestination.h"
#import "MUByteSource.h"
#import "MUAbstractConnection.h"
#import "MUMCPProtocolHandler.h"
#import "MUMCCPProtocolHandler.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetProtocolHandler.h"
#import "MUProtocolStack.h"
#import "MUSocket.h"
#import "MUWriteBuffer.h"

@class MUSocketFactory;
@protocol MUMUDConnectionDelegate;
@protocol MUMUDConnectionDelegate;

extern NSString *MUMUDConnectionDidConnectNotification;
extern NSString *MUMUDConnectionIsConnectingNotification;
extern NSString *MUMUDConnectionWasClosedByClientNotification;
extern NSString *MUMUDConnectionWasClosedByServerNotification;
extern NSString *MUMUDConnectionWasClosedWithErrorNotification;
extern NSString *MUMUDConnectionErrorMessageKey;

@interface MUMUDConnection : MUAbstractConnection <MUSocketDelegate, MUProtocolStackDelegate, MUTelnetProtocolHandlerDelegate, MUMCPProtocolHandlerDelegate, MUMCCPProtocolHandlerDelegate>
{
  MUMUDConnectionState *state;
  MUProtocolStack *protocolStack;
  
  MUSocketFactory *socketFactory;
  
  NSString *hostname;
  int port;
  MUSocket *socket;
  NSTimer *pollTimer;
}

@property (weak, nonatomic) NSObject <MUMUDConnectionDelegate> *delegate;
@property (strong, nonatomic) MUSocket *socket;
@property (strong, nonatomic) MUMUDConnectionState *state;

+ (id) telnetWithSocketFactory: (MUSocketFactory *) factory
                      hostname: (NSString *) hostname
                          port: (int) port
                      delegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

+ (id) telnetWithHostname: (NSString *) hostname
                     port: (int) port
                 delegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

- (id) initWithSocketFactory: (MUSocketFactory *) factory
                    hostname: (NSString *) hostname
                        port: (int) port
                    delegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

- (void) log: (NSString *) message, ...;
- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns;
- (void) writeLine: (NSString *) line;

@end

#pragma mark -

@protocol MUMUDConnectionDelegate

@required
- (void) displayPrompt: (NSString *) promptString;
- (void) displayString: (NSString *) string;
- (void) reportWindowSizeToServer;

@optional
- (void) telnetConnectionDidConnect: (NSNotification *) notification;
- (void) telnetConnectionIsConnecting: (NSNotification *) notification;
- (void) telnetConnectionWasClosedByClient: (NSNotification *) notification;
- (void) telnetConnectionWasClosedByServer: (NSNotification *) notification;
- (void) telnetConnectionWasClosedWithError: (NSNotification *) notification;

@end
