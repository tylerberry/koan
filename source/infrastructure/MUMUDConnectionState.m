//
// MUMUDConnectionState.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUMUDConnectionState.h"

@implementation MUMUDConnectionState

@synthesize charsetNegotiationStatus, isIncomingStreamCompressed, nextTerminalTypeIndex, serverWillEcho;
@synthesize shouldReportWindowSizeChanges, stringEncoding;

+ (id) connectionState
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  isIncomingStreamCompressed = NO;
  nextTerminalTypeIndex = 0;
  serverWillEcho = NO;
  shouldReportWindowSizeChanges = NO;
  stringEncoding = NSASCIIStringEncoding;

  return self;
}

@end
