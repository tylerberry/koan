//
// J3TelnetConnectionState.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3TelnetConnectionState.h"

@implementation J3TelnetConnectionState

@synthesize charsetNegotiationStatus, incomingStreamCompressed, nextTerminalTypeIndex, stringEncoding;

+ (id) connectionState
{
  return [[[self alloc] init] autorelease];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  charsetNegotiationStatus = J3TelnetCharsetNegotiationInactive;
  incomingStreamCompressed = NO;
  nextTerminalTypeIndex = 0;
  stringEncoding = NSASCIIStringEncoding;

  return self;
}

@end
