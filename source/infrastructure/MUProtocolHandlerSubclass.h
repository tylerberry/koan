//
// MUProtocolHandlerSubclass.h
//
// Copyright (c) 2012 3James Software.
//

#import "MUProtocolHandler.h"

@interface MUProtocolHandler ()

- (void) passOnParsedByte: (uint8_t) byte;
- (void) passOnPreprocessedByte: (uint8_t) byte;
- (void) passOnPreprocessedFooterData: (NSData *) footerData;

@end
