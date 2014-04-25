//
//  MUTerminalCSIState.m
//
//  Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUTerminalCSIState.h"

#import "MUTerminalTextState.h"

@implementation MUTerminalCSIState

- (MUTerminalState *) parse: (uint8_t) byte
            forStateMachine: (MUTerminalStateMachine *) stateMachine
            protocolHandler: (NSObject <MUTerminalProtocolHandler> *) protocolHandler
{
  [protocolHandler bufferCommandByte: byte];
  [protocolHandler bufferTextByte: byte];
  NSLog (@"    ANSI: CSI %c", byte);
  return [MUTerminalTextState state];
}

@end
