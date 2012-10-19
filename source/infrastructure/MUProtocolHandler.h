//
// MUProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUProtocolHandler

@required
- (void) notePromptMarker;
- (void) parseByte: (uint8_t) byte;
- (void) preprocessByte: (uint8_t) byte;
- (void) preprocessFooterData: (NSData *) data;

@end

#pragma mark -

@interface MUProtocolHandler : NSObject <MUProtocolHandler>

@property (weak) NSObject <MUProtocolHandler> *previousHandler;
@property (weak) NSObject <MUProtocolHandler> *nextHandler;

@end
