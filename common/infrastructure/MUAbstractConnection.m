//
// MUAbstractConnection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAbstractConnection.h"
#import "MUAbstractConnectionSubclass.h"

@implementation MUAbstractConnection

@dynamic closed, connected, connecting, connectedOrConnecting;

- (instancetype) init
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = MUConnectionStateNotConnected;
  
  return self;
}

#pragma mark - Properties

- (BOOL) isClosed
{
  return _connectionState == MUConnectionStateNotConnected;
}

- (BOOL) isConnected
{
  return _connectionState == MUConnectionStateConnected;
}

- (BOOL) isConnecting
{
  return _connectionState == MUConnectionStateConnecting;
}

- (BOOL) isConnectedOrConnecting
{
  return self.isConnected || self.isConnecting;
}

#pragma mark - Methods

- (void) close
{
  return;
}

- (void) open
{
  return;
}

#pragma mark - Subclass-only methods

- (void) setStatusConnected
{
  _connectionState = MUConnectionStateConnected;
}

- (void) setStatusConnecting
{
  _connectionState = MUConnectionStateConnecting;
}

- (void) setStatusClosedByClient
{
  _connectionState = MUConnectionStateNotConnected;
}

- (void) setStatusClosedByServer
{
  _connectionState = MUConnectionStateNotConnected;
}

- (void) setStatusClosedWithError: (NSError *) error
{
  _connectionState = MUConnectionStateNotConnected;
}

@end
