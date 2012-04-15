//
// MUProtocolStack.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUMUDConnectionState.h"

@class MUByteProtocolHandler;

@class MUProtocolStack;
@protocol MUProtocolStackDelegate;

@interface MUProtocolStack : NSObject
{
  MUMUDConnectionState *connectionState;
  
  NSMutableArray *byteProtocolHandlers;
  NSMutableData *parsingBuffer;
  NSMutableData *preprocessingBuffer;
  
  NSObject <MUProtocolStackDelegate> *delegate;
}

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState;

- (NSObject <MUProtocolStackDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUProtocolStackDelegate> *) newDelegate;

- (void) addByteProtocol: (MUByteProtocolHandler *) protocol;
- (void) clearAllProtocols;

- (void) flushBufferedData;

- (void) parseData: (NSData *) data;
- (NSData *) preprocessOutput: (NSData *) data;

- (void) parseByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler;
- (void) preprocessByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler;

- (void) useBufferedDataAsPrompt;

@end

#pragma mark -

@protocol MUProtocolStackDelegate

- (void) displayDataAsText: (NSData *) parsedData;
- (void) displayDataAsPrompt: (NSData *) parsedData;

@end
