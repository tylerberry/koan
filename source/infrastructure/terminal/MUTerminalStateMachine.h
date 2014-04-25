//
//  MUTerminalStateMachine.h
//  Koan
//
//  Created by Tyler Berry on 4/24/14.
//  Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalProtocolHandler.h"

@class MUTerminalState;

@interface MUTerminalStateMachine : NSObject

@property (strong) MUTerminalState *state;

+ (id) stateMachine;

- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler;

@end
