//
// MUTelnetOption.h
//
// Copyright (c) 2013 3James Software.
//

#define TELNET_OPTION_MAX UINT8_MAX

// This implements the Telnet Q Method: <http://rfc.net/rfc1143.html>

typedef NS_ENUM (NSInteger, MUTelnetQState)
{
  MUTelnetQNo,
  MUTelnetQYes,
  MUTelnetQWantNoEmpty,
  MUTelnetQWantNoOpposite,
  MUTelnetQWantYesEmpty,
  MUTelnetQWantYesOpposite
};

@protocol MUTelnetOptionDelegate

- (void) do: (uint8_t) option;
- (void) dont: (uint8_t) option;
- (void) will: (uint8_t) option;
- (void) wont: (uint8_t) option;

@end

#pragma mark -

@interface MUTelnetOption : NSObject
{
  @protected
  MUTelnetQState _him;
  MUTelnetQState _us;
}

@property (readonly) BOOL enabledForHim;
@property (readonly) BOOL enabledForUs;
@property (assign) BOOL permittedForHim;
@property (assign) BOOL permittedForUs;

+ (NSString *) optionNameForByte: (uint8_t) option;

- (instancetype) initWithOption: (uint8_t) option delegate: (NSObject <MUTelnetOptionDelegate> *) object;

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

@end
