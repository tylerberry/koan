//
// MUTelnetOption.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetOption.h"

#import "MUTelnetConstants.h"

@interface MUTelnetOption ()
{
  NSObject <MUTelnetOptionDelegate> *delegate;
  uint8_t option;
  MUTelnetQState him;
  MUTelnetQState us;
  BOOL heIsAllowed;
  BOOL weAreAllowed;
}

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

#pragma mark -

@implementation MUTelnetOption

+ (NSString *) optionNameForByte: (uint8_t) byte
{
  switch (byte)
  {
    case MUTelnetOptionTransmitBinary:
      return @"TRANSMIT-BINARY";
      
    case MUTelnetOptionEcho:
      return @"ECHO";
      
    case MUTelnetOptionSuppressGoAhead:
      return @"SUPPRESS-GO-AHEAD";
      
    case MUTelnetOptionStatus:
      return @"STATUS";
      
    case MUTelnetOptionTimingMark:
      return @"TIMING-MARK";
      
    case MUTelnetOptionTerminalType:
      return @"TERMINAL-TYPE";
      
    case MUTelnetOptionEndOfRecord:
      return @"END-OF-RECORD";
      
    case MUTelnetOptionNegotiateAboutWindowSize:
      return @"NEGOTIATE-ABOUT-WINDOW-SIZE";
      
    case MUTelnetOptionTerminalSpeed:
      return @"TERMINAL-SPEED";
      
    case MUTelnetOptionToggleFlowControl:
      return @"TOGGLE-FLOW-CONTROL";
      
    case MUTelnetOptionLineMode:
      return @"LINEMODE";
      
    case MUTelnetOptionXDisplayLocation:
      return @"X-DISPLAY-LOCATION";
      
    case MUTelnetOptionEnvironment:
      return @"ENVIRON";
      
    case MUTelnetOptionAuthentication:
      return @"AUTHENTICATION";
      
    case MUTelnetOptionNewEnvironment:
      return @"NEW-ENVIRON";
      
    case MUTelnetOptionCharset:
      return @"CHARSET";
      
    case MUTelnetOptionStartTLS:
      return @"START-TLS";
      
    case MUTelnetOptionMSDP:
      return @"MSDP";
      
    case MUTelnetOptionMSSP:
      return @"MSSP";
      
    case MUTelnetOptionMCCP1:
      return @"MCCP1";
      
    case MUTelnetOptionMCCP2:
      return @"MCCP2";
      
    case MUTelnetOptionMSP:
      return @"MSP";
      
    case MUTelnetOptionMXP:
      return @"MXP";
      
    case MUTelnetOptionZMP:
      return @"ZMP";
      
    case MUTelnetOptionAardwolf:
      return @"AARDWOLF";
      
    case MUTelnetOptionATCP:
      return @"ATCP";
      
    case MUTelnetOptionGMCP:
      return @"GMCP";
      
    default:
      return [NSString stringWithFormat: @"%u (unknown option)", (unsigned) byte];
  }
}

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

- (id) initWithOption: (uint8_t) newOption delegate: (NSObject <MUTelnetOptionDelegate> *) object
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

#pragma mark - Private methods

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

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

#pragma clang diagnostic pop

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
