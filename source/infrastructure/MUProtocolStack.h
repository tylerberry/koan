//
// MUProtocolStack.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@class MUByteProtocolHandler;

@class MUProtocolStack;
@protocol MUProtocolStackDelegate;

@interface MUProtocolStack : NSObject
{
  NSMutableArray *byteProtocolHandlers;
  NSMutableData *parsingBuffer;
  NSMutableData *preprocessingBuffer;
  
  NSObject <MUProtocolStackDelegate> *delegate;
}

- (NSObject <MUProtocolStackDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUProtocolStackDelegate> *) newDelegate;

- (void) addByteProtocol: (MUByteProtocolHandler *) protocol;
- (void) clearAllProtocols;

- (void) flushBufferedData;

- (void) parseData: (NSData *) data;
- (NSData *) preprocessOutput: (NSData *) data;

- (void) parseByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler;
- (void) preprocessByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler;

@end

#pragma mark -

@protocol MUProtocolStackDelegate

- (void) displayData: (NSData *) parsedData;

@end
