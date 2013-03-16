//
// MUMUDConnection.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUAbstractConnection.h"
#import "MUByteDestination.h"
#import "MUByteSource.h"
#import "MUMCPProtocolHandler.h"
#import "MUMCCPProtocolHandler.h"
#import "MUMUDConnectionState.h"
#import "MUProtocolStack.h"
#import "MUTelnetProtocolHandler.h"
#import "MUWriteBuffer.h"

@class MUSocketFactory;

extern NSString *MUMUDConnectionDidConnectNotification;
extern NSString *MUMUDConnectionIsConnectingNotification;
extern NSString *MUMUDConnectionWasClosedByClientNotification;
extern NSString *MUMUDConnectionWasClosedByServerNotification;
extern NSString *MUMUDConnectionWasClosedWithErrorNotification;
extern NSString *MUMUDConnectionErrorKey;

@protocol MUMUDConnectionDelegate

@required
- (void) displayPrompt: (NSString *) promptString;
- (void) displayString: (NSString *) string;
- (void) reportWindowSizeToServer;

@optional
- (void) MUDConnectionDidConnect: (NSNotification *) notification;
- (void) MUDConnectionIsConnecting: (NSNotification *) notification;
- (void) MUDConnectionWasClosedByClient: (NSNotification *) notification;
- (void) MUDConnectionWasClosedByServer: (NSNotification *) notification;
- (void) MUDConnectionWasClosedWithError: (NSNotification *) notification;

@end

#pragma mark -

@interface MUMUDConnection : MUAbstractConnection <NSStreamDelegate, MUHeuristicCodebaseAnalyzerDelegate, MUMCPProtocolHandlerDelegate, MUMCCPProtocolHandlerDelegate, MUProtocolStackDelegate, MUTelnetProtocolHandlerDelegate>

@property (weak, nonatomic) NSObject <MUMUDConnectionDelegate> *delegate;
@property (strong, nonatomic) MUMUDConnectionState *state;

@property (readonly) NSDate *dateConnected;

+ (id) telnetWithHostname: (NSString *) hostname
                     port: (int) port
                 delegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

- (id) initWithHostname: (NSString *) hostname
                   port: (int) port
               delegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns;
- (void) writeLine: (NSString *) line;

@end
