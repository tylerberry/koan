//
// MUProtocolHandler.h
//
// Copyright (c) 2013 3James Software.
//

@class MUProtocolStack;

@protocol MUProtocolHandler

@required
- (void) notePromptMarker;
- (void) parseByte: (uint8_t) byte;
- (void) preprocessByte: (uint8_t) byte;
- (void) preprocessFooterData: (NSData *) data;
- (void) sendPreprocessedData;

@end

#pragma mark -

@interface MUProtocolHandler : NSObject <MUProtocolHandler>

@property (weak) NSObject <MUProtocolHandler> *previousHandler;
@property (weak) MUProtocolStack *protocolStack;
@property (weak) NSObject <MUProtocolHandler> *nextHandler;

@end
