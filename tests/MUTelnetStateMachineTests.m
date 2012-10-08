//
// MUTelnetStateMachineTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetStateMachineTests.h"

#import "MUByteSet.h"
#import "MUTelnetIACState.h"
#import "MUTelnetTextState.h"
#import "MUTelnetDoState.h"
#import "MUTelnetDontState.h"
#import "MUTelnetNotTelnetState.h"
#import "MUTelnetMCCP1SubnegotiationState.h"
#import "MUTelnetStateMachine.h"
#import "MUTelnetSubnegotiationIACState.h"
#import "MUTelnetSubnegotiationOptionState.h"
#import "MUTelnetSubnegotiationState.h"
#import "MUTelnetWillState.h"
#import "MUTelnetWontState.h"
#import "MUWriteBuffer.h"

#define C(x) ([x class])

@interface MUTelnetStateMachineTests (Private)

- (void) assertByteConfirmsTelnet: (uint8_t) byte;
- (void) assertByteInvalidatesTelnet: (uint8_t) byte;
- (void) assertState: (Class) stateClass givenAnyByteProducesState: (Class) nextStateClass;
- (void) assertState: (Class) stateClass givenAnyByteProducesState: (Class) nextStateClass exceptForThoseInSet: (MUByteSet *) exclusions;
- (void) assertState: (Class) stateClass givenByte: (uint8_t) givenByte producesState: (Class) nextStateClass;
- (void) assertState: (Class) stateClass givenByte: (uint8_t) givenByte inputsByte: (uint8_t) inputsByte;
- (void) assertStateObject: (MUTelnetState *) state givenAnyByteProducesState: (Class) nextStateClass exceptForThoseInSet: (MUByteSet *) exclusions;
- (void) assertStateObject: (MUTelnetState *) state givenByte: (uint8_t) byte producesState: (Class) nextStateClass;
- (void) giveStateClass: (Class) stateClass byte: (uint8_t) byte;
- (void) resetStateMachine;

@end

#pragma mark -

@implementation MUTelnetStateMachineTests

- (void) setUp
{
  [self resetStateMachine];
  lastByteInput = -1;
  output = [NSMutableData data];
}

- (void) tearDown
{
  return;
}

- (void) testTextStateTransitions
{
  [self assertState: C(MUTelnetTextState) givenAnyByteProducesState: C(MUTelnetTextState) exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetInterpretAsCommand, -1]];
  [self assertState: C(MUTelnetTextState) givenByte: MUTelnetInterpretAsCommand producesState: C(MUTelnetIACState)];
}

- (void) testIACTransitionsThatInvalidateTelnet
{
  MUByteSet *byteSet = [[MUTelnetState telnetCommandBytes] inverseSet];
  [byteSet addByte: MUTelnetBeginSubnegotiation];
  [byteSet addByte: MUTelnetEndSubnegotiation];
  NSData *bytes = [byteSet dataValue];
  for (unsigned i = 0; i < [bytes length]; ++i)
    [self assertByteInvalidatesTelnet: ((uint8_t *)[bytes bytes])[i]];
}

- (void) testIACTransitionsThatConfirmTelnet
{
  MUByteSet *byteSet = [MUTelnetState telnetCommandBytes];
  [byteSet removeByte: MUTelnetBeginSubnegotiation];
  [byteSet removeByte: MUTelnetEndSubnegotiation];
  [byteSet removeByte: MUTelnetInterpretAsCommand];
  [byteSet removeByte: MUTelnetEndOfRecord];
  NSData *bytes = [byteSet dataValue];
  for (unsigned i = 0; i < [bytes length]; ++i)
    [self assertByteConfirmsTelnet: ((uint8_t *)[bytes bytes])[i]];
}
  
- (void) testIACTransitionsOnceConfirmed
{
  [stateMachine confirmTelnet];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetEndOfRecord producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetNoOperation producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetDataMark producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetBreak producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetInterruptProcess producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetAbortOutput producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetAreYouThere producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetEraseCharacter producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetEraseLine producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetGoAhead producesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetDo producesState: C(MUTelnetDoState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetDont producesState: C(MUTelnetDontState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetWill producesState: C(MUTelnetWillState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetWont producesState: C(MUTelnetWontState)];  
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetBeginSubnegotiation producesState: C(MUTelnetSubnegotiationOptionState)];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetInterpretAsCommand producesState: C(MUTelnetTextState)];
}
  
- (void) testDoWontWillWontStateTransitions
{
  [self assertState: C(MUTelnetDoState) givenAnyByteProducesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetDontState) givenAnyByteProducesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetWillState) givenAnyByteProducesState: C(MUTelnetTextState)];
  [self assertState: C(MUTelnetWontState) givenAnyByteProducesState: C(MUTelnetTextState)];
}

- (void) testInput
{
  [self assertState: C(MUTelnetTextState) givenByte: 'a' inputsByte: 'a'];
  [self assertState: C(MUTelnetIACState) givenByte: MUTelnetInterpretAsCommand inputsByte: MUTelnetInterpretAsCommand];
}

- (void) testSubnegotiationStateTransitions
{
  [self assertState: C(MUTelnetSubnegotiationOptionState) givenAnyByteProducesState: C(MUTelnetSubnegotiationState) exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetInterpretAsCommand, MUTelnetOptionMCCP1, -1]];
  
  [self assertState: C(MUTelnetSubnegotiationState) givenAnyByteProducesState: C(MUTelnetSubnegotiationState) exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetInterpretAsCommand, -1]];
  [self assertState: C(MUTelnetSubnegotiationState) givenByte: MUTelnetInterpretAsCommand producesState: C(MUTelnetSubnegotiationIACState)];
  
  [self assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetSubnegotiationState)] givenAnyByteProducesState: C(MUTelnetSubnegotiationState) exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetEndSubnegotiation, -1]];
  [self assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetSubnegotiationState)] givenByte: MUTelnetEndSubnegotiation producesState: C(MUTelnetTextState)];
}

- (void) testMCCP1NegotiationStateTransitions
{
  [self assertState: C(MUTelnetSubnegotiationOptionState) givenByte: MUTelnetOptionMCCP1 producesState: C(MUTelnetMCCP1SubnegotiationState)];
  
  [self assertState: C(MUTelnetMCCP1SubnegotiationState) givenByte: MUTelnetWill producesState: C(MUTelnetSubnegotiationIACState)];
  
  [self assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetMCCP1SubnegotiationState)] givenAnyByteProducesState: C(MUTelnetMCCP1SubnegotiationState) exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetEndSubnegotiation, -1]];
  [self assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetMCCP1SubnegotiationState)] givenByte: MUTelnetEndSubnegotiation producesState: C(MUTelnetTextState)];
}

#pragma mark - MUTelnetProtocolHandler protocol

- (void) bufferSubnegotiationByte: (uint8_t) byte
{
  lastByteInput = byte;
}

- (void) bufferTextByte: (uint8_t) byte
{
  [output appendBytes: &byte length: 1];
  lastByteInput = byte;
}

- (void) handleBufferedSubnegotiation
{
  return;
}

- (void) log: (NSString *) message, ...
{
  return;
}

- (NSString *) optionNameForByte: (uint8_t) byte
{
  return nil;
}

- (void) receivedDo: (uint8_t) option
{
  return;
}

- (void) receivedDont: (uint8_t) option
{
  return;
}

- (void) receivedWill: (uint8_t) option
{
  return;
}

- (void) receivedWont: (uint8_t) option
{
  return;
}

- (void) useBufferedDataAsPrompt
{
  return;
}

@end

#pragma mark -

@implementation MUTelnetStateMachineTests (Private)

- (void) assertByteConfirmsTelnet: (uint8_t) byte;
{
  [self resetStateMachine];
  [[MUTelnetIACState state] parse: byte forStateMachine: stateMachine protocolHandler: nil];
  [self assertTrue: stateMachine.telnetConfirmed message: [NSString stringWithFormat: @"%d did not confirm telnet", byte]];
  [output setLength: 0];
}

- (void) assertByteInvalidatesTelnet: (uint8_t) byte
{
  [self resetStateMachine];
  uint8_t bytes[] = {MUTelnetInterpretAsCommand, byte};
  [self assertState: C(MUTelnetIACState) givenByte: byte producesState: C(MUTelnetNotTelnetState)];
  [self assert: output equals: [NSData dataWithBytes: bytes length: 2]];
  [output setLength: 0];
}

- (void) assertState: (Class) stateClass givenAnyByteProducesState: (Class) nextStateClass
{
  [self assertState: stateClass givenAnyByteProducesState: nextStateClass exceptForThoseInSet: [MUByteSet byteSet]];
}

- (void) assertState: (Class) stateClass
givenAnyByteProducesState: (Class) nextStateClass
 exceptForThoseInSet: (MUByteSet *) exclusions
{
  [self assertStateObject: [[stateClass alloc] init] givenAnyByteProducesState: nextStateClass exceptForThoseInSet: exclusions];
}

- (void) assertState: (Class) stateClass
           givenByte: (uint8_t) givenByte
       producesState: (Class) nextStateClass
{
  [self assertStateObject: [[stateClass alloc] init]
                givenByte: givenByte
            producesState: nextStateClass];
}

- (void) assertState: (Class) stateClass
           givenByte: (uint8_t) givenByte
          inputsByte: (uint8_t) inputsByte
{
  [self giveStateClass: stateClass byte: givenByte];
  [self assertInt: lastByteInput equals: inputsByte];
}

- (void) assertStateObject: (MUTelnetState *) state
 givenAnyByteProducesState: (Class) nextStateClass
       exceptForThoseInSet: (MUByteSet *) exclusions
{
  NSData *bytes = [[exclusions inverseSet] dataValue];
  for (unsigned i = 0; i < [bytes length]; ++i)
    [self assertStateObject: state givenByte: ((uint8_t *)[bytes bytes])[i] producesState: nextStateClass];
}

- (void) assertStateObject: (MUTelnetState *) state
                 givenByte: (uint8_t) byte
             producesState: (Class) nextStateClass
{
  MUTelnetState *nextState = [state parse: byte forStateMachine: stateMachine protocolHandler: self];
  [self assert: [nextState class] equals: nextStateClass message: [NSString stringWithFormat: @"Byte was 0x%x (%d)", byte, byte]];  
}

- (void) giveStateClass: (Class) stateClass byte: (uint8_t) byte
{
  [[[stateClass alloc] init] parse: byte forStateMachine: stateMachine protocolHandler: self];  
}

- (void) resetStateMachine
{
  
  stateMachine = [MUTelnetStateMachine stateMachine];
}

@end
