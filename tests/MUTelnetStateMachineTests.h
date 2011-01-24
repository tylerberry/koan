//
// MUTelnetStateMachineTests.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import <J3Testing/J3Testcase.h>
#import "MUTelnetProtocolHandler.h"
#import "MUTelnetStateMachine.h"

@interface MUTelnetStateMachineTests : J3TestCase <MUTelnetProtocolHandler>
{
  MUTelnetStateMachine *stateMachine;
  int lastByteInput;
  NSMutableData *output;
}
@end
