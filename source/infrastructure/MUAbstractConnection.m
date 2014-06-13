//
// MUAbstractConnection.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUAbstractConnection.h"
#import "MUAbstractConnectionSubclass.h"

@implementation MUAbstractConnection

@dynamic isClosed, isConnected, isConnecting, isConnectedOrConnecting;

- (instancetype) init
{
  if (!(self = [super init]))
    return nil;
  
  _status = MUConnectionStatusNotConnected;
  
  return self;
}

#pragma mark - Properties

- (BOOL) isClosed
{
  return self.status == MUConnectionStatusNotConnected;
}

- (BOOL) isConnected
{
  return self.status == MUConnectionStatusConnected;
}

- (BOOL) isConnecting
{
  return self.status == MUConnectionStatusConnecting;
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
  _status = MUConnectionStatusConnected;
}

- (void) setStatusConnecting
{
  _status = MUConnectionStatusConnecting;
}

- (void) setStatusClosedByClient
{
  _status = MUConnectionStatusNotConnected;
}

- (void) setStatusClosedByServer
{
  _status = MUConnectionStatusNotConnected;
}

- (void) setStatusClosedWithError: (NSError *) error
{
  _status = MUConnectionStatusNotConnected;
}

@end
