//
// MUTelnetSubnegotiationIACState.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetState.h"

@interface MUTelnetSubnegotiationIACState : MUTelnetState

+ (instancetype) stateWithReturnState: (Class) state;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithReturnState: (Class) state NS_DESIGNATED_INITIALIZER;

@end
