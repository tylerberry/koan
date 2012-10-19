//
// MUProtocolStack.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUMUDConnectionState.h"
#import "MUProtocolHandler.h"

@class MUProtocolStack;
@protocol MUProtocolStackDelegate;

@interface MUProtocolStack : NSObject <MUProtocolHandler>

@property (readonly) NSArray *protocolHandlers;
@property (weak) NSObject <MUProtocolStackDelegate> *delegate;

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState;

- (void) addProtocolHandler: (MUProtocolHandler *) protocolHandler;
- (void) clearAllProtocols;

- (void) flushBufferedData;

- (void) parseInputData: (NSData *) data;
- (NSData *) preprocessOutputData: (NSData *) data;

@end

#pragma mark -

@protocol MUProtocolStackDelegate

- (void) displayDataAsText: (NSData *) parsedData;
- (void) displayDataAsPrompt: (NSData *) parsedData;

@end
