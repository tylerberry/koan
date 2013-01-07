//
// MUTelnetStateMachineTests.h
//
// Copyright (c) 2013 3James Software.
//

#import "J3TestCase.h"
#import "MUTelnetProtocolHandler.h"
#import "MUTelnetStateMachine.h"

@interface MUTelnetStateMachineTests : J3TestCase <MUTelnetProtocolHandler>
{
  MUTelnetStateMachine *stateMachine;
  int lastByteInput;
  NSMutableData *output;
}
@end
