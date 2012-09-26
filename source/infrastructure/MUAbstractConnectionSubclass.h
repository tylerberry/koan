//
// MUAbstractConnection.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUAbstractConnection.h"

@interface MUAbstractConnection ()

- (void) setStatusConnected;
- (void) setStatusConnecting;
- (void) setStatusClosedByClient;
- (void) setStatusClosedByServer;
- (void) setStatusClosedWithError: (NSString *) error;

@end