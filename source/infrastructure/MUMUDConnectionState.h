//
// MUMUDConnectionState.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

enum charsetNegotiationStatus
{
  MUTelnetCharsetNegotiationInactive = 0,
  MUTelnetCharsetNegotiationActive = 1,
  MUTelnetCharsetNegotiationIgnoreRejected = 2
};

@interface MUMUDConnectionState : NSObject
{
  enum charsetNegotiationStatus charsetNegotiationStatus;
  BOOL incomingStreamCompressed;
  unsigned nextTerminalTypeIndex;
  NSStringEncoding stringEncoding;
}

@property (assign, nonatomic) enum charsetNegotiationStatus charsetNegotiationStatus;
@property (assign, nonatomic) BOOL incomingStreamCompressed;
@property (assign, nonatomic) unsigned nextTerminalTypeIndex;
@property (assign, nonatomic) NSStringEncoding stringEncoding;

+ (id) connectionState;

@end
