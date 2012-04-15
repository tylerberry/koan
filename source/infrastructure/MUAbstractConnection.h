//
// MUAbstractConnection.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

typedef enum MUConnectionStatus
{
  MUConnectionStatusNotConnected,
  MUConnectionStatusConnecting,
  MUConnectionStatusConnected,
  MUConnectionStatusClosed
} MUConnectionStatus;

#pragma mark -

@interface MUAbstractConnection : NSObject
{
  MUConnectionStatus status;
}

- (void) close;
- (BOOL) isClosed;
- (BOOL) isConnected;
- (BOOL) isConnecting;
- (void) open;

@end

#pragma mark -

@interface MUAbstractConnection (Protected)

- (void) setStatusConnected;
- (void) setStatusConnecting;
- (void) setStatusClosedByClient;
- (void) setStatusClosedByServer;
- (void) setStatusClosedWithError: (NSString *) error;

@end
