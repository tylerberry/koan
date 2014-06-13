//
// MUTelnetOption.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetOption.h"

#import "MUTelnetConstants.h"

@interface MUTelnetOption ()

@property (weak) NSObject <MUTelnetOptionDelegate> *delegate;

- (void) _demandDisableFor: (MUTelnetQState *) state withSelector: (SEL) selector;
- (void) _receivedDisableDemandForState: (MUTelnetQState *) state
                          ifAcknowledge: (SEL) acknowledge
                                ifAllow: (SEL) allow;
- (void) _receivedEnableRequestForState: (MUTelnetQState *) state
                       shouldEnableFlag: (BOOL) flag
                               ifAccept: (SEL) accept
                               ifReject: (SEL) reject;
- (void) _requestEnableFor: (MUTelnetQState *) state withSelector: (SEL) selector;
- (void) _sendDo;
- (void) _sendDont;
- (void) _sendWill;
- (void) _sendWont;

@end

#pragma mark -

@implementation MUTelnetOption
{
  uint8_t _option;
}

@dynamic enabledForHim, enabledForUs;

+ (NSString *) optionNameForByte: (uint8_t) option
{
  switch (option)
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
      return [NSString stringWithFormat: @"%u (unknown option)", (unsigned) option];
  }
}

- (instancetype) initWithOption: (uint8_t) option delegate: (NSObject <MUTelnetOptionDelegate> *) object
{
  if (!(self = [super init]))
    return nil;

  _option = option;
  _delegate = object;
  _permittedForHim = NO;
  _permittedForUs = NO;
  _him = MUTelnetQNo;
  _us = MUTelnetQNo;

  return self;
}

- (void) disableHim
{
  [self _demandDisableFor: &_him withSelector: @selector (_sendDont)];
}

- (void) disableUs
{
  [self _demandDisableFor: &_us withSelector: @selector (_sendWont)];
}

- (void) enableHim
{
  [self _requestEnableFor: &_him withSelector: @selector (_sendDo)];
}

- (void) enableUs
{
  [self _requestEnableFor: &_us withSelector: @selector (_sendWill)];
}

- (BOOL) enabledForHim
{
  return _him == MUTelnetQYes;
}

- (BOOL) enabledForUs
{
  return _us == MUTelnetQYes;
}

- (void) receivedDo
{
  [self _receivedEnableRequestForState: &_us
                      shouldEnableFlag: self.permittedForUs
                              ifAccept: @selector (_sendWill)
                              ifReject: @selector (_sendWont)];
}

- (void) receivedDont
{
  [self _receivedDisableDemandForState: &_us
                         ifAcknowledge: @selector (_sendWont)
                               ifAllow: @selector (_sendWill)];
}

- (void) receivedWill
{
  [self _receivedEnableRequestForState: &_him
                      shouldEnableFlag: self.permittedForHim
                              ifAccept: @selector (_sendDo)
                              ifReject: @selector (_sendDont)];
}

- (void) receivedWont
{
  [self _receivedDisableDemandForState: &_him
                         ifAcknowledge: @selector (_sendDont)
                               ifAllow: @selector (_sendDo)];
}

#pragma mark - Private methods

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void) _demandDisableFor: (MUTelnetQState *) state withSelector: (SEL) selector
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

- (void) _receivedDisableDemandForState: (MUTelnetQState *) state
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

- (void) _receivedEnableRequestForState: (MUTelnetQState *) state
                       shouldEnableFlag: (BOOL) shouldEnableOption
                               ifAccept: (SEL) accept
                               ifReject: (SEL) reject
{
  switch (*state)
  {
    case MUTelnetQNo:
      if (shouldEnableOption)
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

- (void) _requestEnableFor: (MUTelnetQState *) state withSelector: (SEL) selector
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

- (void) _sendDo
{
  [self.delegate do: _option];
}

- (void) _sendDont
{
  [self.delegate dont: _option];
}

- (void) _sendWill
{
  [self.delegate will: _option];
}

- (void) _sendWont
{
  [self.delegate wont: _option];
}

@end
