//
// MUMUDConnectionState.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

enum charsetNegotiationStatus
{
  MUTelnetCharsetNegotiationInactive = 0,
  MUTelnetCharsetNegotiationActive = 1,
  MUTelnetCharsetNegotiationIgnoreRejected = 2
};

@interface MUMUDConnectionState : NSObject

@property (assign) enum charsetNegotiationStatus charsetNegotiationStatus;
@property (assign) BOOL isIncomingStreamCompressed;
@property (assign) unsigned nextTerminalTypeIndex;
@property (assign) BOOL shouldReportWindowSizeChanges;
@property (assign) BOOL serverWillEcho;
@property (assign) NSStringEncoding stringEncoding;

+ (id) connectionState;

@end
