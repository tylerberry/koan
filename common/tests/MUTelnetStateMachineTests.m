//
// MUTelnetStateMachineTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUByteSet.h"
#import "MUTelnetIACState.h"
#import "MUTelnetTextState.h"
#import "MUTelnetDoState.h"
#import "MUTelnetDontState.h"
#import "MUTelnetNotTelnetState.h"
#import "MUTelnetMCCP1SubnegotiationState.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetSubnegotiationIACState.h"
#import "MUTelnetSubnegotiationOptionState.h"
#import "MUTelnetSubnegotiationState.h"
#import "MUTelnetWillState.h"
#import "MUTelnetWontState.h"

#define C(x) ([x class])

@interface MUTelnetStateMachineTests : XCTestCase <MUTelnetProtocolHandler>

+ (MUByteSet *) _telnetCommandBytes;

- (void) _assertByteConfirmsTelnet: (uint8_t) byte;
- (void) _assertByteInvalidatesTelnet: (uint8_t) byte;
- (void) _assertState: (Class) stateClass givenAnyByteProducesState: (Class) nextStateClass;
- (void)     _assertState: (Class) stateClass
givenAnyByteProducesState: (Class) nextStateClass
      exceptForThoseInSet: (MUByteSet *) exclusions;
- (void) _assertState: (Class) stateClass givenByte: (uint8_t) givenByte producesState: (Class) nextStateClass;
- (void) _assertState: (Class) stateClass givenByte: (uint8_t) givenByte inputsByte: (uint8_t) inputsByte;
- (void) _assertStateObject: (MUTelnetState *) state
  givenAnyByteProducesState: (Class) nextStateClass
        exceptForThoseInSet: (MUByteSet *) exclusions;
- (void) _assertStateObject: (MUTelnetState *) state givenByte: (uint8_t) byte producesState: (Class) nextStateClass;
- (void) _giveStateClass: (Class) stateClass byte: (uint8_t) byte;

@end

#pragma mark -

@implementation MUTelnetStateMachineTests
{
  MUMUDConnectionState *_state;
  int _lastByteInput;
  NSMutableData *_output;
}

- (void) setUp
{
  [super setUp];
  _state = [[MUMUDConnectionState alloc] initWithCodebaseAnalyzerDelegate: nil];
  _lastByteInput = -1;
  _output = [NSMutableData data];
}

- (void) tearDown
{
  _state = nil;
  _output = nil;
  [super tearDown];
}

- (void) testTextStateTransitions
{
  MUByteSet *IACSet = [MUByteSet byteSetWithBytes: MUTelnetInterpretAsCommand, -1];
  [self _assertState: C(MUTelnetTextState) givenAnyByteProducesState: C(MUTelnetTextState) exceptForThoseInSet: IACSet];

  [self _assertState: C(MUTelnetTextState) givenByte: MUTelnetInterpretAsCommand producesState: C(MUTelnetIACState)];
}

- (void) testIACTransitionsThatInvalidateTelnet
{
  MUByteSet *byteSet = [[MUTelnetStateMachineTests _telnetCommandBytes] inverseSet];

  // This should invalidate Telnet, as it violates spec, but it can't actually invalidate it due to server bugs.
  //[byteSet addByte: MUTelnetBeginSubnegotiation];

  [byteSet addByte: MUTelnetEndSubnegotiation];

  NSData *byteSetData = byteSet.dataValue;

  for (NSUInteger i = 0; i < byteSetData.length; i++)
  {
    [self _assertByteInvalidatesTelnet: ((uint8_t *) byteSetData.bytes)[i]];
  }
}

- (void) testIACTransitionsThatConfirmTelnet
{
  MUByteSet *byteSet = [MUTelnetStateMachineTests _telnetCommandBytes];

  [byteSet removeByte: MUTelnetBeginSubnegotiation];
  [byteSet removeByte: MUTelnetEndSubnegotiation];
  [byteSet removeByte: MUTelnetInterpretAsCommand];
  [byteSet removeByte: MUTelnetEndOfRecord];

  NSData *byteSetData = byteSet.dataValue;

  for (NSUInteger i = 0; i < byteSetData.length; i++)
  {
    [self _assertByteConfirmsTelnet: ((uint8_t *) byteSetData.bytes)[i]];
  }
}

- (void) testIACTransitionsOnceConfirmed
{
  _state.telnetConfirmed = YES;

  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetEndOfRecord producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetNoOperation producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetDataMark producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetBreak producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetInterruptProcess producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetAbortOutput producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetAreYouThere producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetEraseCharacter producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetEraseLine producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetGoAhead producesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetDo producesState: C(MUTelnetDoState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetDont producesState: C(MUTelnetDontState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetWill producesState: C(MUTelnetWillState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetWont producesState: C(MUTelnetWontState)];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetInterpretAsCommand producesState: C(MUTelnetTextState)];

  [self _assertState: C(MUTelnetIACState)
           givenByte: MUTelnetBeginSubnegotiation
       producesState: C(MUTelnetSubnegotiationOptionState)];
}

- (void) testDoWontWillWontStateTransitions
{
  [self _assertState: C(MUTelnetDoState) givenAnyByteProducesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetDontState) givenAnyByteProducesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetWillState) givenAnyByteProducesState: C(MUTelnetTextState)];
  [self _assertState: C(MUTelnetWontState) givenAnyByteProducesState: C(MUTelnetTextState)];
}

- (void) testInput
{
  [self _assertState: C(MUTelnetTextState) givenByte: 'a' inputsByte: 'a'];
  [self _assertState: C(MUTelnetIACState) givenByte: MUTelnetInterpretAsCommand inputsByte: MUTelnetInterpretAsCommand];
}

- (void) testSubnegotiationStateTransitions
{
  [self      _assertState: C(MUTelnetSubnegotiationOptionState)
givenAnyByteProducesState: C(MUTelnetSubnegotiationState)
      exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetInterpretAsCommand, MUTelnetOptionMCCP1, -1]];

  [self      _assertState: C(MUTelnetSubnegotiationState)
givenAnyByteProducesState: C(MUTelnetSubnegotiationState)
      exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetInterpretAsCommand, -1]];

  [self _assertState: C(MUTelnetSubnegotiationState)
           givenByte: MUTelnetInterpretAsCommand
       producesState: C(MUTelnetSubnegotiationIACState)];

  [self _assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetSubnegotiationState)]
 givenAnyByteProducesState: C(MUTelnetSubnegotiationState)
       exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetEndSubnegotiation, -1]];

  [self _assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetSubnegotiationState)]
                 givenByte: MUTelnetEndSubnegotiation
             producesState: C(MUTelnetTextState)];
}

- (void) testMCCP1NegotiationStateTransitions
{
  [self _assertState: C(MUTelnetSubnegotiationOptionState)
           givenByte: MUTelnetOptionMCCP1
       producesState: C(MUTelnetMCCP1SubnegotiationState)];

  [self _assertState: C(MUTelnetMCCP1SubnegotiationState)
           givenByte: MUTelnetWill
       producesState: C(MUTelnetSubnegotiationIACState)];

  [self _assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetMCCP1SubnegotiationState)]
 givenAnyByteProducesState: C(MUTelnetMCCP1SubnegotiationState)
       exceptForThoseInSet: [MUByteSet byteSetWithBytes: MUTelnetEndSubnegotiation, -1]];

  [self _assertStateObject: [MUTelnetSubnegotiationIACState stateWithReturnState: C(MUTelnetMCCP1SubnegotiationState)]
                 givenByte: MUTelnetEndSubnegotiation
             producesState: C(MUTelnetTextState)];
}

#pragma mark - MUTelnetProtocolHandler protocol

- (void) bufferSubnegotiationByte: (uint8_t) byte
{
  _lastByteInput = byte;
}

- (void) bufferTextByte: (uint8_t) byte
{
  [_output appendBytes: &byte length: 1];
  _lastByteInput = byte;
}

- (void) deleteLastBufferedCharacter
{
  if (_output.length > 0)
    [_output replaceBytesInRange: NSMakeRange (_output.length - 1, 1) withBytes: NULL length: 0];
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

- (void) sendNAWSSubnegotiationWithNumberOfLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  return;
}

- (void) useBufferedDataAsPrompt
{
  return;
}

#pragma mark - Private methods

+ (MUByteSet *) _telnetCommandBytes
{
  return [MUByteSet byteSetWithBytes:
          MUTelnetEndOfRecord,
          MUTelnetEndSubnegotiation,
          MUTelnetNoOperation,
          MUTelnetDataMark,
          MUTelnetBreak,
          MUTelnetInterruptProcess,
          MUTelnetAbortOutput,
          MUTelnetAreYouThere,
          MUTelnetEraseCharacter,
          MUTelnetEraseLine,
          MUTelnetGoAhead,
          MUTelnetBeginSubnegotiation,
          MUTelnetWill,
          MUTelnetWont,
          MUTelnetDo,
          MUTelnetDont,
          MUTelnetInterpretAsCommand,
          -1];
}

- (void) _assertByteConfirmsTelnet: (uint8_t) byte;
{
  [_state reset];
  [[MUTelnetIACState state] parse: byte
               forConnectionState: _state
                  protocolHandler: nil];
  XCTAssertTrue (_state.telnetConfirmed, @"%d did not confirm telnet", byte);
  [_output replaceBytesInRange: NSMakeRange (0, _output.length) withBytes: NULL length: 0];
}

- (void) _assertByteInvalidatesTelnet: (uint8_t) byte
{
  [_state reset];
  uint8_t bytes[] = {MUTelnetInterpretAsCommand, byte};
  [self _assertState: C(MUTelnetIACState) givenByte: byte producesState: C(MUTelnetNotTelnetState)];
  XCTAssertEqualObjects (_output, [NSData dataWithBytes: bytes length: 2]);
  [_output replaceBytesInRange: NSMakeRange (0, _output.length) withBytes: NULL length: 0];
}

- (void) _assertState: (Class) stateClass givenAnyByteProducesState: (Class) nextStateClass
{
  [self _assertState: stateClass givenAnyByteProducesState: nextStateClass exceptForThoseInSet: [MUByteSet byteSet]];
}

- (void)     _assertState: (Class) stateClass
givenAnyByteProducesState: (Class) nextStateClass
      exceptForThoseInSet: (MUByteSet *) exclusions
{
  [self _assertStateObject: [[stateClass alloc] init]
 givenAnyByteProducesState: nextStateClass
       exceptForThoseInSet: exclusions];
}

- (void) _assertState: (Class) stateClass
            givenByte: (uint8_t) givenByte
        producesState: (Class) nextStateClass
{
  [self _assertStateObject: [[stateClass alloc] init] givenByte: givenByte producesState: nextStateClass];
}

- (void) _assertState: (Class) stateClass givenByte: (uint8_t) givenByte inputsByte: (uint8_t) inputsByte
{
  [self _giveStateClass: stateClass byte: givenByte];

  XCTAssertEqual (_lastByteInput, inputsByte);
}

- (void) _assertStateObject: (MUTelnetState *) state
  givenAnyByteProducesState: (Class) nextStateClass
        exceptForThoseInSet: (MUByteSet *) exclusions
{
  NSData *inverseByteSetData = exclusions.inverseSet.dataValue;

  for (NSUInteger i = 0; i < inverseByteSetData.length; i++)
  {
    [self _assertStateObject: state givenByte: ((uint8_t *) inverseByteSetData.bytes)[i] producesState: nextStateClass];
  }
}

- (void) _assertStateObject: (MUTelnetState *) state givenByte: (uint8_t) byte producesState: (Class) nextStateClass
{
  MUTelnetState *nextState = [state parse: byte forConnectionState: _state protocolHandler: self];
  
  XCTAssertEqualObjects ([nextState class], nextStateClass, @"Byte was 0x%x (%d)", byte, byte);
}

- (void) _giveStateClass: (Class) stateClass byte: (uint8_t) byte
{
  [[[stateClass alloc] init] parse: byte forConnectionState: _state protocolHandler: self];
}

@end
