//
// MUTerminalUnhandledTwoByteCodeState.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalState.h"

@interface MUTerminalUnhandledTwoByteCodeState : MUTerminalState

+ (instancetype) stateWithFirstByte: (uint8_t) firstByte;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithFirstByte: (uint8_t) firstByte NS_DESIGNATED_INITIALIZER;

@end
