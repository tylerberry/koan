//
// MUSocket.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUByteDestination.h"
#import "MUByteSource.h"
#import "MUAbstractConnection.h"

#include <netinet/in.h>

@protocol MUSocketDelegate;

NSString *MUSocketError;

extern NSString *MUSocketDidConnectNotification;
extern NSString *MUSocketIsConnectingNotification;
extern NSString *MUSocketWasClosedByClientNotification;
extern NSString *MUSocketWasClosedByServerNotification;
extern NSString *MUSocketWasClosedWithErrorNotification;
extern NSString *MUSocketErrorMessageKey;

#pragma mark -

@interface MUSocketException : NSException

+ (void) socketError: (NSString *) errorMessage;
+ (void) socketErrorWithFormat: (NSString *) format, ...;

@end

#pragma mark -

@interface MUSocket : MUAbstractConnection <MUByteDestination, MUByteSource>

@property (weak, nonatomic) NSObject <MUSocketDelegate> *delegate;

+ (instancetype) socketWithHostname: (NSString *) hostname port: (uint16_t) port;

- (instancetype) initWithHostname: (NSString *) hostname port: (uint16_t) port;

@end

#pragma mark -

@protocol MUSocketDelegate

- (void) socketDidConnect: (NSNotification *) notification;
- (void) socketIsConnecting: (NSNotification *) notification;
- (void) socketWasClosedByClient: (NSNotification *) notification;
- (void) socketWasClosedByServer: (NSNotification *) notification;
- (void) socketWasClosedWithError: (NSNotification *) notification;

@end
