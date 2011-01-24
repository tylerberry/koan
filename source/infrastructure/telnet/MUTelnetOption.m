//
// MUTelnetOption.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetOption.h"

@interface MUTelnetOption (Private)

- (void) demandDisableFor: (MUTelnetQState *) state withSelector: (SEL) selector;
- (void) receivedDisableDemandForState: (MUTelnetQState *) state
                         ifAcknowledge: (SEL) acknowledge
                               ifAllow: (SEL) allow;
- (void) receivedEnableRequestForState: (MUTelnetQState *) state
                      shouldEnableFlag: (BOOL *) flag
                              ifAccept: (SEL) accept
                              ifReject: (SEL) reject;
- (void) requestEnableFor: (MUTelnetQState *) state withSelector: (SEL) selector;
- (void) sendDo;
- (void) sendDont;
- (void) sendWill;
- (void) sendWont;

@end

@implementation MUTelnetOption

- (void) disableHim
{
  [self demandDisableFor: &him withSelector: @selector (sendDont)];
}

- (void) disableUs
{
  [self demandDisableFor: &us withSelector: @selector (sendWont)];
}

- (BOOL) heIsYes
{
  return him == MUTelnetQYes;
}

- (id) initWithOption: (int) newOption delegate: (NSObject <MUTelnetOptionDelegate> *) object
{
  if (!(self = [super init]))
    return nil;
  option = newOption;
  delegate = object;
  heIsAllowed = NO;
  weAreAllowed = NO;
  him = MUTelnetQNo;
  us = MUTelnetQNo;
  return self;
}

- (void) receivedDo
{
  [self receivedEnableRequestForState: &us 
                     shouldEnableFlag: &weAreAllowed
                             ifAccept: @selector (sendWill) 
                             ifReject: @selector (sendWont)];  
}

- (void) receivedDont
{
  [self receivedDisableDemandForState: &us 
                        ifAcknowledge: @selector (sendWont) 
                              ifAllow: @selector (sendWill)];
}

- (void) receivedWill
{
  [self receivedEnableRequestForState: &him 
                     shouldEnableFlag: &heIsAllowed
                             ifAccept: @selector (sendDo) 
                             ifReject: @selector (sendDont)];
}

- (void) receivedWont
{
  [self receivedDisableDemandForState: &him 
                        ifAcknowledge: @selector (sendDont) 
                              ifAllow: @selector (sendDo)];
}

- (void) enableHim
{
  [self requestEnableFor: &him withSelector: @selector (sendDo)];
}

- (void) enableUs
{
  [self requestEnableFor: &us withSelector: @selector (sendWill)];
}

- (void) heIsAllowedToUse: (BOOL) value
{
  heIsAllowed = value;
}

- (BOOL) weAreYes
{
  return us == MUTelnetQYes;
}

- (void) weAreAllowedToUse: (BOOL) value
{
  weAreAllowed = value;
}

@end

#pragma mark -

@implementation MUTelnetOption (Private)

- (void) demandDisableFor: (MUTelnetQState *) state withSelector: (SEL) selector
{
  switch (*state)
  {
    case MUTelnetQNo:
      break;
      
    case MUTelnetQYes:
      *state = MUTelnetQWantNoEmpty;
      [self performSelector: selector];
      break;
      
    case MUTelnetQWantNoEmpty:
    case MUTelnetQWantNoOpposite:
      *state = MUTelnetQWantNoEmpty;
      break;
      
    case MUTelnetQWantYesEmpty:
    case MUTelnetQWantYesOpposite:
      *state = MUTelnetQWantYesOpposite;
      break;
  }   
}

- (void) receivedDisableDemandForState: (MUTelnetQState *) state
                         ifAcknowledge: (SEL) acknowledge
                               ifAllow: (SEL) allow
{
  switch (*state)
  {
    case MUTelnetQNo:
      break;
      
    case MUTelnetQYes:
      *state = MUTelnetQNo;
      [self performSelector: acknowledge];
      break;
      
    case MUTelnetQWantNoOpposite:
      *state = MUTelnetQWantYesEmpty;
      [self performSelector: allow];
      break;
      
    case MUTelnetQWantNoEmpty:
    case MUTelnetQWantYesEmpty:
    case MUTelnetQWantYesOpposite:
      *state = MUTelnetQNo;
      break;
  }  
}

- (void) receivedEnableRequestForState: (MUTelnetQState *) state
                      shouldEnableFlag: (BOOL *) flag
                              ifAccept: (SEL) accept
                              ifReject: (SEL) reject
{
  switch (*state)
  {
    case MUTelnetQNo:
      if (*flag)
      {
        *state = MUTelnetQYes;
        [self performSelector: accept];
      }
      else
        [self performSelector: reject];
      break;
      
    case MUTelnetQYes:
      break;
      
    case MUTelnetQWantNoEmpty:
      *state = MUTelnetQNo;
      break;
      
    case MUTelnetQWantNoOpposite:
    case MUTelnetQWantYesEmpty:
      *state = MUTelnetQYes;
      break;
      
    case MUTelnetQWantYesOpposite:
      *state = MUTelnetQWantNoEmpty;
      [self performSelector: reject];
      break;
  }
}

- (void) requestEnableFor: (MUTelnetQState *) state withSelector: (SEL) selector
{
  switch (*state)
  {
    case MUTelnetQNo:
      *state = MUTelnetQWantYesEmpty;
      [self performSelector: selector];
      break;
      
    case MUTelnetQYes:
      break;
      
    case MUTelnetQWantNoEmpty:
    case MUTelnetQWantNoOpposite:
      *state = MUTelnetQWantNoOpposite;
      break;
      
    case MUTelnetQWantYesEmpty: 
    case MUTelnetQWantYesOpposite:
      *state = MUTelnetQWantYesEmpty;
      break;
  }
}

- (void) sendDo
{
  [delegate do: option];
}

- (void) sendDont
{
  [delegate dont: option];
}

- (void) sendWill
{
  [delegate will: option];
}

- (void) sendWont
{
  [delegate wont: option];
}

@end
