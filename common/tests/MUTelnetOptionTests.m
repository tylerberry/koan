//
// MUTelnetOptionTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetOption.h"

#define DO 0x01
#define DONT 0x02
#define WILL 0x04
#define WONT 0x08

#define QSTATES 6

typedef int MUQMethodTable[QSTATES][3];

#pragma mark -

@interface MUTelnetOption (TestAccessors)

- (MUTelnetQState) _him;
- (void) _setHim: (MUTelnetQState) state;
- (MUTelnetQState) _us;
- (void) _setUs: (MUTelnetQState) state;

@end

#pragma mark -

@implementation MUTelnetOption (TestAccessors)

- (MUTelnetQState) _him
{
  return _him;
}

- (void) _setHim: (MUTelnetQState) state
{
  _him = state;
}

- (MUTelnetQState) _us
{
  return _us;
}

- (void) _setUs: (MUTelnetQState) state
{
  _us = state;
}

@end

#pragma mark -

@interface MUTelnetOptionTests : XCTestCase <MUTelnetOptionDelegate>

- (void) assertQMethodTable: (MUQMethodTable) table forSelector: (SEL) selector forHimOrUs: (SEL) himOrUs;
- (void) assertWhenSelector: (SEL) selector
          isCalledFromState: (MUTelnetQState) startState
                 forHimOrUs: (SEL) himOrUs
        theResultingStateIs: (MUTelnetQState) endState
                   andCalls: (int) flags;
- (void) clearFlags;
- (NSString *) qStateName: (MUTelnetQState) state;

@end

#pragma mark -

@implementation MUTelnetOptionTests
{
  MUTelnetOption *_option;
  char _flags;
}

- (void) setUp
{
  [super setUp];
  [self clearFlags];
  _option = [[MUTelnetOption alloc] initWithOption: 0 delegate: self];
}

- (void) tearDown
{
  _option = nil;
  [super tearDown];
}

- (void) testReceivedWont
{
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            0},
    {MUTelnetQYes,              MUTelnetQNo,            DONT},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},
    {MUTelnetQWantNoOpposite,   MUTelnetQWantYesEmpty,  DO},
    {MUTelnetQWantYesEmpty,     MUTelnetQNo,            0},
    {MUTelnetQWantYesOpposite,  MUTelnetQNo,            0},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedWont) forHimOrUs: @selector (_him)];
}

- (void) testReceivedDont
{
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            0},
    {MUTelnetQYes,              MUTelnetQNo,            WONT},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},
    {MUTelnetQWantNoOpposite,   MUTelnetQWantYesEmpty,  WILL},
    {MUTelnetQWantYesEmpty,     MUTelnetQNo,            0},
    {MUTelnetQWantYesOpposite,  MUTelnetQNo,            0},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedDont) forHimOrUs: @selector (_us)];
}

- (void) testReceivedWillAndWeDoNotWantTo
{
  _option.permittedForHim = NO;
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            DONT},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   DONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedWill) forHimOrUs: @selector (_him)];
}

- (void) testReceivedWillAndWeDoWantTo
{
  _option.permittedForHim = YES;
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQYes,           DO},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   DONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedWill) forHimOrUs: @selector (_him)];
}

- (void) testReceivedDoAndWeDoNotWantTo
{
  _option.permittedForUs = NO;
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            WONT},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   WONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedDo) forHimOrUs: @selector (_us)];
}

- (void) testReceivedDoAndWeDoWantTo
{
  _option.permittedForUs = YES;
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQYes,           WILL},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   WONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedDo) forHimOrUs: @selector (_us)];
}

- (void) testEnableHimWithQueue
{
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQWantYesEmpty,    DO},
    {MUTelnetQYes,              MUTelnetQYes,             0},   // error
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoOpposite,  0},   
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoOpposite,  0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesEmpty,    0},   // error
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesEmpty,    0},
  };
  [self assertQMethodTable: table forSelector: @selector (enableHim) forHimOrUs: @selector (_him)];
}

- (void) testEnableUsWithQueue
{
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQWantYesEmpty,    WILL},
    {MUTelnetQYes,              MUTelnetQYes,             0},   // error
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoOpposite,  0},   
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoOpposite,  0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesEmpty,    0},   // error
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesEmpty,    0},
  };
  [self assertQMethodTable: table forSelector: @selector (enableUs) forHimOrUs: @selector (_us)];
}

- (void) testDisableHimWithQueue
{
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,              0},   // error
    {MUTelnetQYes,              MUTelnetQWantNoEmpty,     DONT},   
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoEmpty,     0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoEmpty,     0},   
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesOpposite, 0},   
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesOpposite, 0},   // error
  };
  [self assertQMethodTable: table forSelector: @selector (disableHim) forHimOrUs: @selector (_him)];
}

- (void) testDisableUsWithQueue
{
  MUQMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,              0},   // error
    {MUTelnetQYes,              MUTelnetQWantNoEmpty,     WONT},   
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoEmpty,     0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoEmpty,     0},   
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesOpposite, 0},   
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesOpposite, 0},   // error
  };
  [self assertQMethodTable: table forSelector: @selector (disableUs) forHimOrUs: @selector (_us)];
}

- (void) testHeIsEnabled
{
  MUTelnetQState noStates[5] = {MUTelnetQNo, MUTelnetQWantNoEmpty, MUTelnetQWantNoOpposite,
    MUTelnetQWantYesEmpty, MUTelnetQWantYesOpposite};
  for (unsigned i = 0; i < 5; ++i)
  {
    [_option _setHim: noStates[i]];
    XCTAssertFalse (_option.enabledForHim, @"%@", [self qStateName: noStates[i]]);
  }
  [_option _setHim: MUTelnetQYes];
  XCTAssertTrue (_option.enabledForHim);
}

- (void) testWeAreEnabled
{
  MUTelnetQState noStates[5] = {MUTelnetQNo, MUTelnetQWantNoEmpty, MUTelnetQWantNoOpposite,
    MUTelnetQWantYesEmpty, MUTelnetQWantYesOpposite};
  for (unsigned i = 0; i < 5; ++i)
  {
    [_option _setUs: noStates[i]];
    XCTAssertFalse (_option.enabledForUs, @"%@", [self qStateName: noStates[i]]);
  }
  [_option _setUs: MUTelnetQYes];
  XCTAssertTrue (_option.enabledForUs);
}

#pragma mark - MUTelnetOptionDelegate protocol

- (void) do: (uint8_t) option
{
  _flags = _flags | DO;
}

- (void) dont: (uint8_t) option
{
  _flags = _flags | DONT;
}

- (void) will: (uint8_t) option
{
  _flags = _flags | WILL;
}

- (void) wont: (uint8_t) option
{
  _flags = _flags | WONT;
}

#pragma mark - Private methods

- (void) assertQMethodTable: (MUQMethodTable) table forSelector: (SEL) selector forHimOrUs: (SEL) himOrUs
{
  for (unsigned i = 0; i < QSTATES; ++i)
  {
    [self assertWhenSelector: selector
           isCalledFromState: table[i][0]
                  forHimOrUs: himOrUs
         theResultingStateIs: table[i][1]
                    andCalls: table[i][2]];
  }  
}

- (void) assertWhenSelector: (SEL) selector
          isCalledFromState: (MUTelnetQState) startState
                 forHimOrUs: (SEL) himOrUs
        theResultingStateIs: (MUTelnetQState) endState
                   andCalls: (int) expectedFlags;
{
  NSString *message = [self qStateName: startState];
  
  [self clearFlags];
  
  if (himOrUs == @selector (_him))
    [_option _setHim: startState];
  else
    [_option _setUs: startState];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  
  [_option performSelector: selector];
  
  XCTAssertEqual ((MUTelnetQState) [_option performSelector: himOrUs], endState, @"%@ ending state", message);

#pragma clang diagnostic pop
  
  XCTAssertEqual (_flags, expectedFlags, @"%@ flags", message);
}

- (void) clearFlags
{
  _flags = 0;
}

- (NSString *) qStateName: (MUTelnetQState) state
{
  switch (state)
  {
    case MUTelnetQNo:
      return @"MUTelnetQNo";
    case MUTelnetQYes:
      return @"MUTelnetQYes";
    case MUTelnetQWantNoEmpty:
      return @"MUTelnetQWantNoEmpty";
    case MUTelnetQWantNoOpposite:
      return @"MUTelnetQWantNoOpposite";
    case MUTelnetQWantYesEmpty:
      return @"MUTelnetQWantYesEmpty";
    case MUTelnetQWantYesOpposite:
      return @"MUTelnetQWantYesOpposite";
    default:
      return @"Unknown";
  }
}

@end
