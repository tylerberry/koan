//
// MUAbstractConnection.h
//
// Copyright (c) 2013 3James Software.
//

typedef enum MUConnectionStatus
{
  MUConnectionStatusNotConnected,
  MUConnectionStatusConnecting,
  MUConnectionStatusConnected
} MUConnectionStatus;

#pragma mark -

@interface MUAbstractConnection : NSObject

@property (readonly) MUConnectionStatus status;

@property (readonly) BOOL isClosed;
@property (readonly) BOOL isConnected;
@property (readonly) BOOL isConnecting;

@property (readonly) BOOL isConnectedOrConnecting;

- (void) close;
- (void) open;

@end
