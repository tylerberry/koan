//
// J3Protocol.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3Protocol.h"

@implementation J3ByteProtocolHandler

+ (id) protocolHandlerWithStack: (J3ProtocolStack *) stack
{
  return [[[self alloc] initWithStack: stack] autorelease];
}

- (id) initWithStack: (J3ProtocolStack *) stack
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

#pragma mark -

@implementation J3ProtocolStack

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  byteProtocolHandlers = [[NSMutableArray alloc] init];
  parsingBuffer = nil;
  preprocessingBuffer = nil;
  
  return self;
}

- (void) dealloc
{
  [byteProtocolHandlers release];
  [parsingBuffer release];
  [preprocessingBuffer release];
  [super dealloc];
}

- (NSObject <J3ProtocolStackDelegate> *) delegate
{
  return delegate;
}

- (void) setDelegate: (NSObject <J3ProtocolStackDelegate> *) newDelegate
{
  delegate = newDelegate;
}

- (void) addByteProtocol: (J3ByteProtocolHandler *) protocol
{
  [byteProtocolHandlers addObject: protocol];
}

- (void) clearAllProtocols
{
  [byteProtocolHandlers removeAllObjects];
}

- (void) parseData: (NSData *) data
{
  if ([byteProtocolHandlers count] == 0)
    return;
  
  const uint8_t *bytes = [data bytes];
  unsigned dataLength = [data length];
  
  if (!parsingBuffer)
    parsingBuffer = [[NSMutableData alloc] initWithCapacity: dataLength];
  
  unsigned firstLevel = [byteProtocolHandlers count] - 1;
  J3ByteProtocolHandler *firstProtocolHandler = [byteProtocolHandlers objectAtIndex: firstLevel];
  
  for (unsigned i = 0; i < dataLength; i++)
    [firstProtocolHandler parseByte: bytes[i]];
  
  if ([parsingBuffer length] == 0)
  {
    [parsingBuffer release];
    parsingBuffer = nil;
  }
}

- (NSData *) preprocessOutput: (NSData *) data
{
  if ([byteProtocolHandlers count] == 0)
    return nil;
  
  const uint8_t *bytes = [data bytes];
  unsigned dataLength = [data length];
  
  preprocessingBuffer = [[NSMutableData alloc] initWithCapacity: dataLength];
  
  for (J3ByteProtocolHandler *handler in byteProtocolHandlers)
    [preprocessingBuffer appendData: [handler headerForPreprocessedData]];
  
  unsigned firstLevel = 0;
  J3ByteProtocolHandler *firstProtocolHandler = [byteProtocolHandlers objectAtIndex: firstLevel];
  
  for (unsigned i = 0; i < dataLength; i++)
    [firstProtocolHandler preprocessByte: bytes[i]];
  
  for (J3ByteProtocolHandler *handler in byteProtocolHandlers)
    [preprocessingBuffer appendData: [handler footerForPreprocessedData]];
  
  NSData *preprocessedData = preprocessingBuffer;
  preprocessingBuffer = nil;
  
  return [preprocessedData autorelease];
}

- (void) parseByte: (uint8_t) byte previousProtocolHandler: (J3ByteProtocolHandler *) previousHandler
{
  unsigned previousLevel = [byteProtocolHandlers indexOfObject: previousHandler];
  if (previousLevel > 0)
  {
    int nextLevel = previousLevel - 1;
    J3ByteProtocolHandler *nextProtocolHandler = [byteProtocolHandlers objectAtIndex: nextLevel];
    [nextProtocolHandler parseByte: byte];
  }
  else
  {
    [parsingBuffer appendBytes: &byte length: 1];
    if (byte == '\n')
    {
      [delegate displayData: [NSData dataWithData: parsingBuffer]];
      [parsingBuffer setData: [NSData data]];
    }
  }
}

- (void) preprocessByte: (uint8_t) byte previousProtocolHandler: (J3ByteProtocolHandler *) previousHandler
{
  unsigned previousLevel = [byteProtocolHandlers indexOfObject: previousHandler];
  if (previousLevel < [byteProtocolHandlers count] - 1)
  {
    int nextLevel = previousLevel + 1;
    J3ByteProtocolHandler *nextProtocolHandler = [byteProtocolHandlers objectAtIndex: nextLevel];
    [nextProtocolHandler preprocessByte: byte];
  }
  else
    [preprocessingBuffer appendBytes: &byte length: 1];
}

@end
