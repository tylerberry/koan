//
// MUMUDConnectionState.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnectionState.h"

@implementation MUMUDConnectionState

- (instancetype) initWithCodebaseAnalyzerDelegate: (NSObject <MUHeuristicCodebaseAnalyzerDelegate> *) newDelegate;
{
  if (!(self = [super init]))
    return nil;
  
  _codebaseAnalyzer = [[MUHeuristicCodebaseAnalyzer alloc] initWithDelegate: newDelegate];
  
  _charsetNegotiationState = MUCharsetNegotiationStateInactive;
  _incomingStreamCompressed = NO;
  _allowCodePage437Substitution = YES; // Defaulting to YES allows some MUSHes that can't negotiate to work properly.
  _nextTerminalTypeIndex = 0;
  _serverWillEcho = NO;
  _shouldReportWindowSizeChanges = NO;
  _stringEncoding = NSASCIIStringEncoding;

  return self;
}

- (instancetype) init
{
  return [self initWithCodebaseAnalyzerDelegate: nil];
}

- (void) reset
{
  [_codebaseAnalyzer reset];
  
  self.charsetNegotiationState = MUCharsetNegotiationStateInactive;
  self.incomingStreamCompressed = NO;
  self.allowCodePage437Substitution = YES;
  self.nextTerminalTypeIndex = 0;
  self.serverWillEcho = NO;
  self.shouldReportWindowSizeChanges = NO;
  self.stringEncoding = NSASCIIStringEncoding;

}

@end
