//
// MUTelnetSubnegotiationIACState.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetState.h"

@interface MUTelnetSubnegotiationIACState : MUTelnetState

+ (id) stateWithReturnState: (Class) state;

- (id) initWithReturnState: (Class) state;

@end
