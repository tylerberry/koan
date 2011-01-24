//
// MUProtocolStack.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUProtocolStack.h"

#import "MUByteProtocolHandler.h"

@implementation MUProtocolStack

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

- (NSObject <MUProtocolStackDelegate> *) delegate
{
  return delegate;
}

- (void) setDelegate: (NSObject <MUProtocolStackDelegate> *) newDelegate
{
  delegate = newDelegate;
}

- (void) addByteProtocol: (MUByteProtocolHandler *) protocol
{
  [byteProtocolHandlers addObject: protocol];
}

- (void) clearAllProtocols
{
  [byteProtocolHandlers removeAllObjects];
}

- (void) flushBufferedData
{
  if (parsingBuffer && [parsingBuffer length] > 0)
  {
    [delegate displayData: [NSData dataWithData: parsingBuffer]];
    [parsingBuffer setData: [NSData data]];
  }
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
  MUByteProtocolHandler *firstProtocolHandler = [byteProtocolHandlers objectAtIndex: firstLevel];
  
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
  
  for (MUByteProtocolHandler *handler in byteProtocolHandlers)
    [preprocessingBuffer appendData: [handler headerForPreprocessedData]];
  
  unsigned firstLevel = 0;
  MUByteProtocolHandler *firstProtocolHandler = [byteProtocolHandlers objectAtIndex: firstLevel];
  
  for (unsigned i = 0; i < dataLength; i++)
    [firstProtocolHandler preprocessByte: bytes[i]];
  
  for (MUByteProtocolHandler *handler in byteProtocolHandlers)
    [preprocessingBuffer appendData: [handler footerForPreprocessedData]];
  
  NSData *preprocessedData = preprocessingBuffer;
  preprocessingBuffer = nil;
  
  return [preprocessedData autorelease];
}

- (void) parseByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler
{
  unsigned previousLevel = [byteProtocolHandlers indexOfObject: previousHandler];
  if (previousLevel > 0)
  {
    int nextLevel = previousLevel - 1;
    MUByteProtocolHandler *nextProtocolHandler = [byteProtocolHandlers objectAtIndex: nextLevel];
    [nextProtocolHandler parseByte: byte];
  }
  else
  {
    [parsingBuffer appendBytes: &byte length: 1];
    
    if (byte == '\n')
      [self flushBufferedData];
  }
}

- (void) preprocessByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler
{
  unsigned previousLevel = [byteProtocolHandlers indexOfObject: previousHandler];
  if (previousLevel < [byteProtocolHandlers count] - 1)
  {
    int nextLevel = previousLevel + 1;
    MUByteProtocolHandler *nextProtocolHandler = [byteProtocolHandlers objectAtIndex: nextLevel];
    [nextProtocolHandler preprocessByte: byte];
  }
  else
    [preprocessingBuffer appendBytes: &byte length: 1];
}

@end
