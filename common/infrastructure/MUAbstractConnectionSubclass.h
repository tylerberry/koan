//
// MUAbstractConnectionSubclass.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUAbstractConnection.h"

@interface MUAbstractConnection ()
{
@protected
  MUConnectionState _connectionState;
}

- (void) setStatusConnected;
- (void) setStatusConnecting;
- (void) setStatusClosedByClient;
- (void) setStatusClosedByServer;
- (void) setStatusClosedWithError: (NSError *) error;

@end
