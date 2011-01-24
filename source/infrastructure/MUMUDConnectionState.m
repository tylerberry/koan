//
// MUMUDConnectionState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUMUDConnectionState.h"

@implementation MUMUDConnectionState

@synthesize charsetNegotiationStatus, incomingStreamCompressed, nextTerminalTypeIndex, stringEncoding;

+ (id) connectionState
{
  return [[[self alloc] init] autorelease];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  incomingStreamCompressed = NO;
  nextTerminalTypeIndex = 0;
  stringEncoding = NSASCIIStringEncoding;

  return self;
}

@end
