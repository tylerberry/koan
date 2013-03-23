//
// MUMUDConnectionState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnectionState.h"

@implementation MUMUDConnectionState

- (id) initWithCodebaseAnalyzerDelegate: (NSObject <MUHeuristicCodebaseAnalyzerDelegate> *) newDelegate;
{
  if (!(self = [super init]))
    return nil;
  
  _codebaseAnalyzer = [[MUHeuristicCodebaseAnalyzer alloc] initWithDelegate: newDelegate];
  
  _charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  _isIncomingStreamCompressed = NO;
  _needsSingleByteSocketReads = NO;
  _nextTerminalTypeIndex = 0;
  _serverWillEcho = NO;
  _shouldReportWindowSizeChanges = NO;
  _stringEncoding = NSASCIIStringEncoding;

  return self;
}

- (id) init
{
  return [self initWithCodebaseAnalyzerDelegate: nil];
}

- (void) reset
{
  [_codebaseAnalyzer reset];
  
  self.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  self.isIncomingStreamCompressed = NO;
  self.needsSingleByteSocketReads = NO;
  self.nextTerminalTypeIndex = 0;
  self.serverWillEcho = NO;
  self.shouldReportWindowSizeChanges = NO;
  self.stringEncoding = NSASCIIStringEncoding;
}

@end
