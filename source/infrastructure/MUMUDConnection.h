//
// MUMUDConnection.h
//
// Copyright (c) 2013 3James Software.
//

#import "GCDAsyncSocket.h"
#import "MUAbstractConnection.h"
#import "MUFugueEditFilter.h"
#import "MUMCPProtocolHandler.h"
#import "MUMCCPProtocolHandler.h"
#import "MUMUDConnectionState.h"
#import "MUProfile.h"
#import "MUProtocolStack.h"
#import "MUTelnetProtocolHandler.h"
#import "MUTerminalProtocolHandler.h"

@class MUSocketFactory;

extern NSString *MUMUDConnectionDidConnectNotification;
extern NSString *MUMUDConnectionIsConnectingNotification;
extern NSString *MUMUDConnectionWasClosedByClientNotification;
extern NSString *MUMUDConnectionWasClosedByServerNotification;
extern NSString *MUMUDConnectionWasClosedWithErrorNotification;
extern NSString *MUMUDConnectionErrorKey;

@protocol MUMUDConnectionDelegate

@required
- (void) displayAttributedStringAsPrompt: (NSAttributedString *) attributedString;
- (void) displayAttributedString: (NSAttributedString *) attributedString;
- (void) reportWindowSizeToServer;

@optional
- (void) MUDConnectionDidConnect: (NSNotification *) notification;
- (void) MUDConnectionIsConnecting: (NSNotification *) notification;
- (void) MUDConnectionWasClosedByClient: (NSNotification *) notification;
- (void) MUDConnectionWasClosedByServer: (NSNotification *) notification;
- (void) MUDConnectionWasClosedWithError: (NSNotification *) notification;

@end

#pragma mark -

@interface MUMUDConnection : MUAbstractConnection <GCDAsyncSocketDelegate, MUHeuristicCodebaseAnalyzerDelegate, MUMCPProtocolHandlerDelegate, MUMCCPProtocolHandlerDelegate, MUProtocolStackDelegate, MUTerminalProtocolHandlerDelegate, MUTelnetProtocolHandlerDelegate>

@property (readonly) MUProfile *profile;
@property (strong, nonatomic) MUMUDConnectionState *state;
@property (readonly) NSDictionary *textAttributes;
@property (weak, nonatomic) NSObject <MUMUDConnectionDelegate> *delegate;

@property (readonly) NSDate *dateConnected;

+ (instancetype) connectionWithProfile: (MUProfile *) profile
                              delegate: (NSObject <MUMUDConnectionDelegate, MUFugueEditFilterDelegate> *) delegate;

- (instancetype) initWithProfile: (MUProfile *) profile
                        delegate: (NSObject <MUMUDConnectionDelegate, MUFugueEditFilterDelegate> *) delegate;

- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns;
- (void) writeLine: (NSString *) line;

@end
