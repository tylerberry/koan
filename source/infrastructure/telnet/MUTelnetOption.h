//
// MUTelnetOption.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

#define TELNET_OPTION_MAX UINT8_MAX

// This implements the Telnet Q Method: <http://rfc.net/rfc1143.html>

typedef enum MUTelnetQ {
  MUTelnetQNo,
  MUTelnetQYes,
  MUTelnetQWantNoEmpty,
  MUTelnetQWantNoOpposite,
  MUTelnetQWantYesEmpty,
  MUTelnetQWantYesOpposite
} MUTelnetQState;

@protocol MUTelnetOptionDelegate;

@interface MUTelnetOption : NSObject 
{
  NSObject <MUTelnetOptionDelegate> *delegate;
  int option;
  MUTelnetQState him;
  MUTelnetQState us;
  BOOL heIsAllowed;
  BOOL weAreAllowed;
}

+ (NSString *) optionNameForByte: (uint8_t) byte;

- (id) initWithOption: (int) option delegate: (NSObject <MUTelnetOptionDelegate> *) object;

// Negotiation we respond to.
- (void) receivedDo;
- (void) receivedDont;
- (void) receivedWill;
- (void) receivedWont;

// Negotiation we start.
- (void) disableHim;
- (void) disableUs;
- (void) enableHim;
- (void) enableUs;

// Determining if options should be or are enabled.
- (BOOL) heIsYes;
- (void) heIsAllowedToUse: (BOOL) value;
- (BOOL) weAreYes;
- (void) weAreAllowedToUse: (BOOL) value;

@end

@protocol MUTelnetOptionDelegate

- (void) do: (uint8_t) option;
- (void) dont: (uint8_t) option;
- (void) will: (uint8_t) option;
- (void) wont: (uint8_t) option;

@end
