//
// MUByteProtocolHandler.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUProtocolStack.h"

@interface MUByteProtocolHandler : NSObject
{
  MUProtocolStack *protocolStack;
}

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack;
- (id) initWithStack: (MUProtocolStack *) stack;

- (void) parseByte: (uint8_t) byte;

- (NSData *) headerForPreprocessedData;
- (NSData *) footerForPreprocessedData;
- (void) preprocessByte: (uint8_t) byte;

@end
