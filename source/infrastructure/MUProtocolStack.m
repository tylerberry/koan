//
// MUProtocolStack.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProtocolStack.h"

#import "MUProtocolHandler.h"

@interface MUProtocolStack ()
{
  MUMUDConnectionState *connectionState;
  
  NSMutableData *parsingBuffer;
  NSMutableData *preprocessingBuffer;
}

@property (strong) NSMutableArray *mutableProtocolHandlers;

- (void) maybeUseBufferedDataAsPrompt;
- (void) useBufferedDataAsPrompt;

@end

#pragma mark -

@implementation MUProtocolStack

@dynamic protocolHandlers;

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState
{
  if (!(self = [super init]))
    return nil;
                                             
  connectionState = newConnectionState;
  _mutableProtocolHandlers = [[NSMutableArray alloc] init];
  parsingBuffer = [[NSMutableData alloc] initWithCapacity: 2048];
  preprocessingBuffer = nil;
  
  return self;
}

- (void) addProtocolHandler: (MUProtocolHandler *) protocolHandler
{
  @synchronized (self)
  {
    MUProtocolHandler *lastHandler = [self.mutableProtocolHandlers lastObject];
    if (lastHandler)
    {
      protocolHandler.previousHandler = lastHandler;
      lastHandler.nextHandler = protocolHandler;
    }
    else
      protocolHandler.previousHandler = self;
    protocolHandler.nextHandler = self;
    [self.mutableProtocolHandlers addObject: protocolHandler];
  }
}

- (void) clearAllProtocols
{
  @synchronized (self)
  {
    [_mutableProtocolHandlers removeAllObjects];
  }
}

- (void) flushBufferedData
{
  if (parsingBuffer.length > 0)
  {
    [self.delegate displayDataAsText: [NSData dataWithData: parsingBuffer]];
    [parsingBuffer setData: [NSData data]];
  }
}

#pragma mark - Properties

- (NSArray *) protocolHandlers
{
  @synchronized (self)
  {
    return self.mutableProtocolHandlers;
  }
}

#pragma mark - Methods

- (void) parseInputData: (NSData *) data
{
  if (self.protocolHandlers.count == 0)
    return;
  
  const uint8_t *bytes = data.bytes;
  
  NSUInteger firstLevel = self.protocolHandlers.count - 1;
  MUProtocolHandler *firstProtocolHandler = self.protocolHandlers[firstLevel];
  
  for (NSUInteger i = 0; i < data.length; i++)
    [firstProtocolHandler parseByte: bytes[i]];
    
  if (parsingBuffer.length > 0)
    [self maybeUseBufferedDataAsPrompt];
}

- (NSData *) preprocessOutputData: (NSData *) data
{
  if (self.protocolHandlers.count == 0)
    return nil;
  
  const uint8_t *bytes = data.bytes;
  
  preprocessingBuffer = [[NSMutableData alloc] initWithCapacity: data.length];
  
  MUProtocolHandler *firstProtocolHandler = self.protocolHandlers[0];
  
  for (NSUInteger i = 0; i < data.length; i++)
    [firstProtocolHandler preprocessByte: bytes[i]];
  
  [firstProtocolHandler preprocessFooterData: [NSData data]];
  
  NSData *preprocessedData = preprocessingBuffer;
  preprocessingBuffer = nil;
  
  return preprocessedData;
}

#pragma mark - MUProtocolHandler protocol

// These methods handle the endpoints of the protocol stack. Once parsing or preprocessing is completed, the last
// handler with respect to direction pass the final parsed or preprocessed byte back to the stack. The structure looks
// like this, with arrows representing previousHandler and nextHandler properties on the protocol handlers:
//
// stack <-- protocol 1 <--> protocol 2 <--> protocol 3 --> stack
//
// The stack's job is to buffer the incoming bytes and either 1. for parsed data, buffer it into lines then send it to
// the view controller for display, or 2. for preprocessed data, to buffer it and send it to the socket.

- (void) notePromptMarker
{
  [self useBufferedDataAsPrompt];
}

- (void) parseByte: (uint8_t) byte
{
  [parsingBuffer appendBytes: &byte length: 1];
    
  if (byte == '\n')
    [self flushBufferedData];
}

- (void) preprocessByte: (uint8_t) byte
{
  [preprocessingBuffer appendBytes: &byte length: 1];
}

- (void) preprocessFooterData: (NSData *) data
{
  [preprocessingBuffer appendData: data];
}

#pragma mark - Private methods

- (void) maybeUseBufferedDataAsPrompt
{
  NSString *promptCandidate = [[NSString alloc] initWithBytes: parsingBuffer.bytes
                                                       length: parsingBuffer.length
                                                     encoding: connectionState.stringEncoding];
  
  if ([promptCandidate hasSuffix: @" "])
  {
    promptCandidate = [promptCandidate stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    if ([[NSCharacterSet characterSetWithCharactersInString: @">?|:)]"] characterIsMember:
         [promptCandidate characterAtIndex: promptCandidate.length - 1]])
      [self useBufferedDataAsPrompt];
  }
}

- (void) useBufferedDataAsPrompt
{
  if (parsingBuffer.length > 0)
  {
    [self.delegate displayDataAsPrompt: [NSData dataWithData: parsingBuffer]];
    [parsingBuffer setData: [NSData data]];
  }
}

@end
