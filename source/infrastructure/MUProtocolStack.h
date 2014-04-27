//
// MUProtocolStack.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnectionState.h"
#import "MUProtocolHandler.h"

@class MUProtocolStack;

@protocol MUProtocolStackDelegate

@required
- (void) appendStringToLineBuffer: (NSString *) string;
- (void) displayBufferedStringAsText;
- (void) displayBufferedStringAsPrompt;
- (void) maybeDisplayBufferedStringAsPrompt;
- (void) writeDataToSocket: (NSData *) preprocessedData;

@end

#pragma mark -

@interface MUProtocolStack : NSObject <MUProtocolHandler>

@property (readonly) NSArray *protocolHandlers;
@property (weak) NSObject <MUProtocolStackDelegate> *delegate;

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState;

- (void) deleteLastBufferedCharacter;
- (void) flushBufferedData;
- (void) maybeUseBufferedDataAsPrompt;

- (void) parseInputData: (NSData *) data;
- (void) preprocessOutputData: (NSData *) data;

- (void) addProtocolHandler: (MUProtocolHandler *) protocolHandler;
- (void) clearAllProtocols;

@end
