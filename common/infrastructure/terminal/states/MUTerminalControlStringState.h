//
// MUTerminalControlStringState.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalState.h"

@interface MUTerminalControlStringState : MUTerminalState

+ (instancetype) stateWithControlStringType: (MUTerminalControlStringType) controlStringType;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithControlStringType: (MUTerminalControlStringType) controlStringType NS_DESIGNATED_INITIALIZER;

@end
