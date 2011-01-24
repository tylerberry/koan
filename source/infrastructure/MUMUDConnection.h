//
// MUMUDConnection.h
//
// Copyright (c) 2011 3James Software.
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
  NSObject <MUMUDConnectionDelegate> *delegate;
  MUMUDConnectionState *state;
  MUProtocolStack *protocolStack;
  
  MUSocketFactory *socketFactory;
  
  NSString *hostname;
  int port;
  MUSocket *socket;
  NSTimer *pollTimer;
}

@property (assign, nonatomic) NSObject <MUMUDConnectionDelegate> *delegate;
@property (retain, nonatomic) MUSocket *socket;
@property (retain, nonatomic) MUMUDConnectionState *state;

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
- (void) writeLine: (NSString *) line;

@end

#pragma mark -

@protocol MUMUDConnectionDelegate

- (void) displayString: (NSString *) string;

- (void) telnetConnectionDidConnect: (NSNotification *) notification;
- (void) telnetConnectionIsConnecting: (NSNotification *) notification;
- (void) telnetConnectionWasClosedByClient: (NSNotification *) notification;
- (void) telnetConnectionWasClosedByServer: (NSNotification *) notification;
- (void) telnetConnectionWasClosedWithError: (NSNotification *) notification;

@end
