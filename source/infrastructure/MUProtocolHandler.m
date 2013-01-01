//
// MUProtocolHandler.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUProtocolStack.h"

@implementation MUProtocolHandler

+ (id) protocolHandler
{
  return [[self alloc] init];
}

#pragma mark - MUProtocolHandler protocol

- (void) notePromptMarker
{
  [self.protocolStack notePromptMarker];
}

- (void) parseByte: (uint8_t) byte
{
  [self passOnParsedByte: byte];
}

- (void) preprocessByte: (uint8_t) byte
{
  [self passOnPreprocessedByte: byte];
}

- (void) preprocessFooterData: (NSData *) footerData
{
  [self passOnPreprocessedFooterData: footerData];
}

- (void) sendPreprocessedData
{
  [self.protocolStack sendPreprocessedData];
}

#pragma mark - Subclass-only methods

- (void) passOnParsedByte: (uint8_t) byte
{
  [self.previousHandler parseByte: byte];
}

- (void) passOnPreprocessedByte: (uint8_t) byte
{
  [self.nextHandler preprocessByte: byte];
}

- (void) passOnPreprocessedFooterData: (NSData *) footerData
{
  [self.nextHandler preprocessFooterData: footerData];
}

@end
