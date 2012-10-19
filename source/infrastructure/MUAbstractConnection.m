//
// MUAbstractConnection.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUAbstractConnection.h"
#import "MUAbstractConnectionSubclass.h"

@implementation MUAbstractConnection

@synthesize status;
@dynamic isClosed, isConnected, isConnecting;

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  status = MUConnectionStatusNotConnected;
  
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
  status = MUConnectionStatusConnected;
}

- (void) setStatusConnecting
{
  status = MUConnectionStatusConnecting;
}

- (void) setStatusClosedByClient
{
  status = MUConnectionStatusNotConnected;
}

- (void) setStatusClosedByServer
{
  status = MUConnectionStatusNotConnected;
}

- (void) setStatusClosedWithError: (NSString *) error
{
  status = MUConnectionStatusNotConnected;
}

@end
