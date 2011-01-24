//
// MUAbstractConnection.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUAbstractConnection.h"

@implementation MUAbstractConnection

- (void) close
{
  return;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  status = MUConnectionStatusNotConnected;
  
  return self;
}

- (BOOL) isClosed
{
  return status == MUConnectionStatusClosed;
}

- (BOOL) isConnected
{
  return status == MUConnectionStatusConnected;
}

- (BOOL) isConnecting
{
  return status == MUConnectionStatusConnecting;
}

- (void) open
{
  return;
}

@end

#pragma mark -

@implementation MUAbstractConnection (Protected)

- (void) setStatusConnected
{
  status = MUConnectionStatusConnected;
}

- (void) setStatusConnecting
{
  status = MUConnectionStatusConnecting;
}

- (void) setStatusClosedByClient
{
  status = MUConnectionStatusClosed;
}

- (void) setStatusClosedByServer
{
  status = MUConnectionStatusClosed;
}

- (void) setStatusClosedWithError: (NSString *) error
{
  status = MUConnectionStatusClosed;
}

@end
