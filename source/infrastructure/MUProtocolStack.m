//
// MUProtocolStack.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProtocolStack.h"

#import "MUByteProtocolHandler.h"

@interface MUProtocolStack (Private)

- (void) maybeUseBufferedDataAsPrompt;

@end

#pragma mark -

@implementation MUProtocolStack

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState
{
  if (!(self = [super init]))
    return nil;
                                             
  connectionState = newConnectionState;
  byteProtocolHandlers = [[NSMutableArray alloc] init];
  parsingBuffer = [[NSMutableData alloc] initWithCapacity: 2048];
  preprocessingBuffer = nil;
  
  return self;
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
  if ([parsingBuffer length] > 0)
  {
    [delegate displayDataAsText: [NSData dataWithData: parsingBuffer]];
    [parsingBuffer setData: [NSData data]];
  }
}

- (void) parseInputData: (NSData *) data
{
  if ([byteProtocolHandlers count] == 0)
    return;
  
  const uint8_t *bytes = [data bytes];
  NSUInteger dataLength = [data length];
  
  NSUInteger firstLevel = [byteProtocolHandlers count] - 1;
  MUByteProtocolHandler *firstProtocolHandler = byteProtocolHandlers[firstLevel];
  
  for (NSUInteger i = 0; i < dataLength; i++)
    [firstProtocolHandler parseByte: bytes[i]];
    
  if ([parsingBuffer length] > 0)
    [self maybeUseBufferedDataAsPrompt];
}

- (NSData *) preprocessOutputData: (NSData *) data
{
  if ([byteProtocolHandlers count] == 0)
    return nil;
  
  const uint8_t *bytes = [data bytes];
  NSUInteger dataLength = [data length];
  
  preprocessingBuffer = [[NSMutableData alloc] initWithCapacity: dataLength];
  
  for (MUByteProtocolHandler *handler in byteProtocolHandlers)
    [preprocessingBuffer appendData: [handler headerForPreprocessedData]];
  
  NSUInteger firstLevel = 0;
  MUByteProtocolHandler *firstProtocolHandler = byteProtocolHandlers[firstLevel];
  
  for (NSUInteger i = 0; i < dataLength; i++)
    [firstProtocolHandler preprocessByte: bytes[i]];
  
  for (MUByteProtocolHandler *handler in byteProtocolHandlers)
    [preprocessingBuffer appendData: [handler footerForPreprocessedData]];
  
  NSData *preprocessedData = preprocessingBuffer;
  preprocessingBuffer = nil;
  
  return preprocessedData;
}

- (void) parseInputByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler
{
  NSUInteger previousLevel = [byteProtocolHandlers indexOfObject: previousHandler];
  if (previousLevel > 0)
  {
    NSUInteger nextLevel = previousLevel - 1;
    MUByteProtocolHandler *nextProtocolHandler = byteProtocolHandlers[nextLevel];
    [nextProtocolHandler parseByte: byte];
  }
  else
  {
    [parsingBuffer appendBytes: &byte length: 1];
    
    if (byte == '\n')
      [self flushBufferedData];
  }
}

- (void) preprocessOutputByte: (uint8_t) byte previousProtocolHandler: (MUByteProtocolHandler *) previousHandler
{
  NSUInteger previousLevel = [byteProtocolHandlers indexOfObject: previousHandler];
  if (previousLevel < [byteProtocolHandlers count] - 1)
  {
    NSUInteger nextLevel = previousLevel + 1;
    MUByteProtocolHandler *nextProtocolHandler = byteProtocolHandlers[nextLevel];
    [nextProtocolHandler preprocessByte: byte];
  }
  else
    [preprocessingBuffer appendBytes: &byte length: 1];
}

- (void) useBufferedDataAsPrompt
{
  if ([parsingBuffer length] > 0)
  {
    [delegate displayDataAsPrompt: [NSData dataWithData: parsingBuffer]];
    [parsingBuffer setData: [NSData data]];
  }
}

@end

#pragma mark -

@implementation MUProtocolStack (Private)

- (void) maybeUseBufferedDataAsPrompt
{
  NSString *promptCandidate = [[NSString alloc] initWithBytes: [parsingBuffer bytes]
                                                        length: [parsingBuffer length]
                                                      encoding: connectionState.stringEncoding];
  
  if ([promptCandidate hasSuffix: @" "])
  {
    promptCandidate = [promptCandidate stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    if ([[NSCharacterSet characterSetWithCharactersInString: @">?|:)]"] characterIsMember: [promptCandidate characterAtIndex: [promptCandidate length] - 1]])
      [self useBufferedDataAsPrompt];
  }
}

@end
