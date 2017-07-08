//
// MUAbstractConnection.h
//
// Copyright (c) 2013 3James Software.
//

typedef NS_ENUM (NSInteger, MUConnectionState)
{
  MUConnectionStateNotConnected,
  MUConnectionStateConnecting,
  MUConnectionStateConnected
};

#pragma mark -

@interface MUAbstractConnection : NSObject

@property (readonly,getter=isClosed) BOOL closed;
@property (readonly,getter=isConnected) BOOL connected;
@property (readonly,getter=isConnecting) BOOL connecting;

@property (readonly,getter=isConnectedOrConnecting) BOOL connectedOrConnecting;

- (void) close;
- (void) open;

@end
