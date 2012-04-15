//
// MUTelnetOptionTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetOptionTests.h"

#define DO 0x01
#define DONT 0x02
#define WILL 0x04
#define WONT 0x08

#define QSTATES 6

#pragma mark -

typedef int QMethodTable[QSTATES][3];

#pragma mark -

@interface MUTelnetOptionTests (Private)

- (void) assertQMethodTable: (QMethodTable) table forSelector: (SEL) selector forHimOrUs: (SEL) himOrUs;
- (void) assertWhenSelector: (SEL) selector
          isCalledFromState: (MUTelnetQState) startState
                 forHimOrUs: (SEL) himOrUs
        theResultingStateIs: (MUTelnetQState) endState
                   andCalls: (char) flags;
- (void) clearFlags;
- (NSString *) qStateName: (MUTelnetQState) state;

@end

#pragma mark -

@interface MUTelnetOption (TestAccessors)

- (MUTelnetQState) him;
- (void) setHim: (MUTelnetQState) state;
- (MUTelnetQState) us;
- (void) setUs: (MUTelnetQState) state;

@end

#pragma mark -

@implementation MUTelnetOptionTests

- (void) setUp
{
  [super setUp];
  [self clearFlags];
  option = [[MUTelnetOption alloc] initWithOption: 0 delegate: self];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testReceivedWont
{
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            0},
    {MUTelnetQYes,              MUTelnetQNo,            DONT},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},
    {MUTelnetQWantNoOpposite,   MUTelnetQWantYesEmpty,  DO},
    {MUTelnetQWantYesEmpty,     MUTelnetQNo,            0},
    {MUTelnetQWantYesOpposite,  MUTelnetQNo,            0},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedWont) forHimOrUs: @selector (him)];
}

- (void) testReceivedDont
{
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            0},
    {MUTelnetQYes,              MUTelnetQNo,            WONT},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},
    {MUTelnetQWantNoOpposite,   MUTelnetQWantYesEmpty,  WILL},
    {MUTelnetQWantYesEmpty,     MUTelnetQNo,            0},
    {MUTelnetQWantYesOpposite,  MUTelnetQNo,            0},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedDont) forHimOrUs: @selector (us)];
}

- (void) testReceivedWillAndWeDoNotWantTo
{
  [option heIsAllowedToUse: NO];
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            DONT},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   DONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedWill) forHimOrUs: @selector (him)];  
}

- (void) testReceivedWillAndWeDoWantTo
{
  [option heIsAllowedToUse: YES];
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQYes,           DO},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   DONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedWill) forHimOrUs: @selector (him)];    
}

- (void) testReceivedDoAndWeDoNotWantTo
{
  [option weAreAllowedToUse: NO];
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,            WONT},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   WONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedDo) forHimOrUs: @selector (us)];    
}

- (void) testReceivedDoAndWeDoWantTo
{
  [option weAreAllowedToUse: YES];
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQYes,           WILL},
    {MUTelnetQYes,              MUTelnetQYes,           0},
    {MUTelnetQWantNoEmpty,      MUTelnetQNo,            0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQYes,           0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQYes,           0},
    {MUTelnetQWantYesOpposite,  MUTelnetQWantNoEmpty,   WONT},
  };
  [self assertQMethodTable: table forSelector: @selector (receivedDo) forHimOrUs: @selector (us)];    
}

- (void) testEnableHimWithQueue
{
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQWantYesEmpty,    DO},
    {MUTelnetQYes,              MUTelnetQYes,             0},   // error
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoOpposite,  0},   
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoOpposite,  0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesEmpty,    0},   // error
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesEmpty,    0},
  };
  [self assertQMethodTable: table forSelector: @selector (enableHim) forHimOrUs: @selector (him)];    
}

- (void) testEnableUsWithQueue
{
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQWantYesEmpty,    WILL},
    {MUTelnetQYes,              MUTelnetQYes,             0},   // error
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoOpposite,  0},   
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoOpposite,  0},   // error
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesEmpty,    0},   // error
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesEmpty,    0},
  };
  [self assertQMethodTable: table forSelector: @selector (enableUs) forHimOrUs: @selector (us)];    
}

- (void) testDisableHimWithQueue
{
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,              0},   // error
    {MUTelnetQYes,              MUTelnetQWantNoEmpty,     DONT},   
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoEmpty,     0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoEmpty,     0},   
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesOpposite, 0},   
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesOpposite, 0},   // error
  };
  [self assertQMethodTable: table forSelector: @selector (disableHim) forHimOrUs: @selector (him)];    
}

- (void) testDisableUsWithQueue
{
  QMethodTable table = {
    {MUTelnetQNo,               MUTelnetQNo,              0},   // error
    {MUTelnetQYes,              MUTelnetQWantNoEmpty,     WONT},   
    {MUTelnetQWantNoEmpty,      MUTelnetQWantNoEmpty,     0},   // error
    {MUTelnetQWantNoOpposite,   MUTelnetQWantNoEmpty,     0},   
    {MUTelnetQWantYesEmpty,     MUTelnetQWantYesOpposite, 0},   
    {MUTelnetQWantYesOpposite,  MUTelnetQWantYesOpposite, 0},   // error
  };
  [self assertQMethodTable: table forSelector: @selector (disableUs) forHimOrUs: @selector (us)];    
}

- (void) testHeIsEnabled
{
  MUTelnetQState noStates[5] = {MUTelnetQNo, MUTelnetQWantNoEmpty, MUTelnetQWantNoOpposite,
    MUTelnetQWantYesEmpty, MUTelnetQWantYesOpposite};
  for (unsigned i = 0; i < 5; ++i)
  {
    [option setHim: noStates[i]];
    [self assertFalse: [option heIsYes]  message: [self qStateName: noStates[i]]];
  }
  [option setHim: MUTelnetQYes];
  [self assertTrue: [option heIsYes]];
}

- (void) testWeAreEnabled
{
  MUTelnetQState noStates[5] = {MUTelnetQNo, MUTelnetQWantNoEmpty, MUTelnetQWantNoOpposite,
    MUTelnetQWantYesEmpty, MUTelnetQWantYesOpposite};
  for (unsigned i = 0; i < 5; ++i)
  {
    [option setUs: noStates[i]];
    [self assertFalse: [option weAreYes] message: [self qStateName: noStates[i]]];
  }
  [option setUs: MUTelnetQYes];
  [self assertTrue: [option weAreYes]];
}

#pragma mark -
#pragma mark MUTelnetOptionDelegate protocol

- (void) do: (uint8_t) option
{
  flags = flags | DO;
}

- (void) dont: (uint8_t) option
{
  flags = flags | DONT;
}

- (void) will: (uint8_t) option
{
  flags = flags | WILL;
}

- (void) wont: (uint8_t) option
{
  flags = flags | WONT;
}

@end

#pragma mark -

@implementation MUTelnetOptionTests (Private)

- (void) assertQMethodTable: (QMethodTable) table forSelector: (SEL) selector forHimOrUs: (SEL) himOrUs
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
                   andCalls: (char) expectedFlags;
{
  NSString *message = [self qStateName: startState];
  
  [self clearFlags];
  
  if (himOrUs == @selector (him))
    [option setHim: startState];
  else
    [option setUs: startState];
  
  [option performSelector: selector];
  
  [self assertInt: (MUTelnetQState) [option performSelector: himOrUs]
           equals: endState
          message: [NSString stringWithFormat: @"%@ ending state", message]];
  [self assertInt: flags
           equals: expectedFlags
          message: [NSString stringWithFormat: @"%@ flags", message]];
}

- (void) clearFlags
{
  flags = 0;
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

@implementation MUTelnetOption (TestAccessors)

- (MUTelnetQState) him
{
  return him;
}

- (void) setHim: (MUTelnetQState) state
{
  him = state;
}

- (MUTelnetQState) us
{
  return us;
}

- (void) setUs: (MUTelnetQState) state
{
  us = state;
}

@end
