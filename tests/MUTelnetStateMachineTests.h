//
// MUTelnetStateMachineTests.h
//
// Copyright (c) 2013 3James Software.
//



#import "MUTelnetProtocolHandler.h"
#import "MUTelnetStateMachine.h"

@interface MUTelnetStateMachineTests : XCTestCase
 <MUTelnetProtocolHandler>
{
  MUTelnetStateMachine *stateMachine;
  int lastByteInput;
  NSMutableData *output;
}
@end
