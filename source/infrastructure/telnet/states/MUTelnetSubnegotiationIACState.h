//
// MUTelnetSubnegotiationIACState.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetState.h"

@interface MUTelnetSubnegotiationIACState : MUTelnetState
{
  Class returnState;
}

+ (id) stateWithReturnState: (Class) state;

- (id) initWithReturnState: (Class) state;

@end
