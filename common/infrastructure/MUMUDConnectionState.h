//
// MUMUDConnectionState.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUHeuristicCodebaseAnalyzer.h"

typedef NS_ENUM (NSInteger, MUCharsetNegotiationState)
{
  MUCharsetNegotiationStateInactive = 0,
  MUCharsetNegotiationStateActive = 1,
  MUCharsetNegotiationStateIgnoreRejected = 2
};

@interface MUMUDConnectionState : NSObject

@property (strong, nonatomic) MUHeuristicCodebaseAnalyzer *codebaseAnalyzer;

@property (assign) MUCharsetNegotiationState charsetNegotiationState;
@property (assign) BOOL allowCodePage437Substitution;
@property (assign, getter=isIncomingStreamCompressed) BOOL incomingStreamCompressed;
@property (assign) unsigned nextTerminalTypeIndex;
@property (assign) BOOL shouldReportWindowSizeChanges;
@property (assign) BOOL serverWillEcho;
@property (assign) NSStringEncoding stringEncoding;

- (instancetype) initWithCodebaseAnalyzerDelegate: (NSObject <MUHeuristicCodebaseAnalyzerDelegate> *) newDelegate;

- (void) reset;

@end
