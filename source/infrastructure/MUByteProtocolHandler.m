//
// MUByteProtocolHandler.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUByteProtocolHandler.h"

@implementation MUByteProtocolHandler

+ (id) protocolHandlerWithStack: (MUProtocolStack *) stack
{
  return [[[self alloc] initWithStack: stack] autorelease];
}

- (id) initWithStack: (MUProtocolStack *) stack
{
  if (!(self = [super init]))
    return nil;
  
  protocolStack = [stack retain];
  
  return self;
}

- (void) dealloc
{
  [protocolStack release];
  [super dealloc];
}

- (void) parseByte: (uint8_t) byte
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -[parseByte:]"
                               userInfo: nil];
}

- (NSData *) headerForPreprocessedData
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -[headerForPreprocessedData]"
                               userInfo: nil];
}

- (NSData *) footerForPreprocessedData
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -[footerForPreprocessedData]"
                               userInfo: nil];
}

- (void) preprocessByte: (uint8_t) byte
{
  @throw [NSException exceptionWithName: @"SubclassResponsibility"
                                 reason: @"Subclass failed to implement -[preprocessByte:]"
                               userInfo: nil];
}

@end
