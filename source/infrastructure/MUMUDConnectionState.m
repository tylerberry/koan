//
// MUMUDConnectionState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnectionState.h"

@implementation MUMUDConnectionState

+ (id) connectionState
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  _isIncomingStreamCompressed = NO;
  _nextTerminalTypeIndex = 0;
  _serverWillEcho = NO;
  _shouldReportWindowSizeChanges = NO;
  _stringEncoding = NSASCIIStringEncoding;

  return self;
}

- (void) reset
{
  self.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  self.isIncomingStreamCompressed = NO;
  self.nextTerminalTypeIndex = 0;
  self.serverWillEcho = NO;
  self.shouldReportWindowSizeChanges = NO;
  self.stringEncoding = NSASCIIStringEncoding;
}

@end
