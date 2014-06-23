//
// MUTerminalControlStringState.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalState.h"

@interface MUTerminalControlStringState : MUTerminalState

+ (instancetype) stateWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType;

- (instancetype) initWithControlStringType: (enum MUTerminalControlStringTypes) controlStringType;

@end
