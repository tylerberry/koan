//
// MUTerminalControlStringState.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalState.h"

@interface MUTerminalControlStringState : MUTerminalState

+ (id) stateWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType;

- (id) initWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType;

@end
