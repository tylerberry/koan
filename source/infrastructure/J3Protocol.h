//
// J3Protocol.h
//
// Copyright (c) 2010 3James Software.
//

#import <Cocoa/Cocoa.h>

@class J3ProtocolStack;
@protocol J3ProtocolStackDelegate;

@interface J3ByteProtocolHandler : NSObject
{
  J3ProtocolStack *protocolStack;
}

+ (id) protocolHandlerWithStack: (J3ProtocolStack *) stack;
- (id) initWithStack: (J3ProtocolStack *) stack;

- (void) parseByte: (uint8_t) byte;

- (NSData *) headerForPreprocessedData;
- (NSData *) footerForPreprocessedData;
- (void) preprocessByte: (uint8_t) byte;

@end

#pragma mark -

@interface J3ProtocolStack : NSObject
{
  NSMutableArray *byteProtocolHandlers;
  NSMutableData *parsingBuffer;
  NSMutableData *preprocessingBuffer;
  
  NSObject <J3ProtocolStackDelegate> *delegate;
}

- (NSObject <J3ProtocolStackDelegate> *) delegate;
- (void) setDelegate: (NSObject <J3ProtocolStackDelegate> *) newDelegate;

- (void) addByteProtocol: (J3ByteProtocolHandler *) protocol;
- (void) clearAllProtocols;

- (void) parseData: (NSData *) data;
- (NSData *) preprocessOutput: (NSData *) data;

- (void) parseByte: (uint8_t) byte previousProtocolHandler: (J3ByteProtocolHandler *) previousHandler;
- (void) preprocessByte: (uint8_t) byte previousProtocolHandler: (J3ByteProtocolHandler *) previousHandler;

@end

#pragma mark -

@protocol J3ProtocolStackDelegate

- (void) displayData: (NSData *) parsedData;

@end
