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
  BOOL serverWillEcho;
  NSStringEncoding stringEncoding;
}

@property (assign, nonatomic) enum charsetNegotiationStatus charsetNegotiationStatus;
@property (assign, nonatomic) BOOL incomingStreamCompressed;
@property (assign, nonatomic) unsigned nextTerminalTypeIndex;
@property (assign, nonatomic) BOOL serverWillEcho;
@property (assign, nonatomic) NSStringEncoding stringEncoding;

+ (id) connectionState;

@end
