//
// MUTelnetSubnegotiationIACState.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetState.h"

@interface MUTelnetSubnegotiationIACState : MUTelnetState

+ (instancetype) stateWithReturnState: (Class) state;

- (instancetype) initWithReturnState: (Class) state;

@end
