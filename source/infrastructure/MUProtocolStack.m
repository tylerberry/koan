//
// MUProtocolStack.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolStack.h"

#import "MUProtocolHandler.h"

@interface MUProtocolStack ()
{
  MUMUDConnectionState *_connectionState;
  
  NSMutableArray *_mutableProtocolHandlers;
  NSMutableData *_parsingBuffer;
  NSMutableData *_preprocessingBuffer;
  NSMutableArray *_preprocessingBufferStack;
}

- (void) maybeUseBufferedDataAsPrompt;
- (void) sendPreprocessedDataToSocket;
- (void) useBufferedDataAsPrompt;

@end

#pragma mark -

@implementation MUProtocolStack

@dynamic protocolHandlers;

- (id) initWithConnectionState: (MUMUDConnectionState *) newConnectionState
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = newConnectionState;
  
  _mutableProtocolHandlers = [[NSMutableArray alloc] init];
  _parsingBuffer = [[NSMutableData alloc] initWithCapacity: 2048];
  _preprocessingBuffer = [[NSMutableData alloc] initWithCapacity: 2048];
  _preprocessingBufferStack = [[NSMutableArray alloc] init];
  
  return self;
}

#pragma mark - Properties

- (NSArray *) protocolHandlers
{
  @synchronized (_mutableProtocolHandlers)
  {
    return _mutableProtocolHandlers;
  }
}

#pragma mark - Methods

- (void) flushBufferedData
{
  if (_parsingBuffer.length > 0)
  {
    [self.delegate displayDataAsText: [NSData dataWithData: _parsingBuffer]];
    [_parsingBuffer setData: [NSData data]];
  }
}

- (void) parseInputData: (NSData *) data
{
  if (self.protocolHandlers.count == 0)
    return;
  
  const uint8_t *bytes = data.bytes;
  
  NSUInteger firstLevel = self.protocolHandlers.count - 1;
  MUProtocolHandler *firstProtocolHandler = self.protocolHandlers[firstLevel];
  
  for (NSUInteger i = 0; i < data.length; i++)
    [firstProtocolHandler parseByte: bytes[i]];
    
  if (_parsingBuffer.length > 0)
    [self maybeUseBufferedDataAsPrompt];
}

- (void) preprocessOutputData: (NSData *) data
{
  if (self.protocolHandlers.count == 0)
    return;
  
  MUProtocolHandler *firstProtocolHandler = self.protocolHandlers[0];
  const uint8_t *bytes = data.bytes;
  
  for (NSUInteger i = 0; i < data.length; i++)
    [firstProtocolHandler preprocessByte: bytes[i]];
  
  [firstProtocolHandler preprocessFooterData: [NSData data]];
  
  [self sendPreprocessedDataToSocket];
}

#pragma mark - Methods - managing protocol handlers

- (void) addProtocolHandler: (MUProtocolHandler *) protocolHandler
{
  @synchronized (_mutableProtocolHandlers)
  {
    MUProtocolHandler *lastProtocolHandler = [_mutableProtocolHandlers lastObject];
    
    if (lastProtocolHandler)
    {
      protocolHandler.previousHandler = lastProtocolHandler;
      lastProtocolHandler.nextHandler = protocolHandler;
    }
    else
      protocolHandler.previousHandler = self;
    
    protocolHandler.nextHandler = self;
    protocolHandler.protocolStack = self;
    
    [_mutableProtocolHandlers addObject: protocolHandler];
  }
}

- (void) clearAllProtocols
{
  @synchronized (_mutableProtocolHandlers)
  {
    [_mutableProtocolHandlers removeAllObjects];
  }
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
  [_parsingBuffer appendBytes: &byte length: 1];
    
  if (byte == '\n')
    [self flushBufferedData];
}

- (void) preprocessByte: (uint8_t) byte
{
  [_preprocessingBuffer appendBytes: &byte length: 1];
}

- (void) preprocessFooterData: (NSData *) data
{
  [_preprocessingBuffer appendData: data];
}

- (void) sendPreprocessedData
{
  [self sendPreprocessedDataToSocket];
}

#pragma mark - Private methods

- (void) maybeUseBufferedDataAsPrompt
{
  if (_connectionState.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH) // TinyMUSH does not use prompts.
    return;                                                                         // PennMUSH does, though.
  
  NSString *promptCandidate = [[NSString alloc] initWithBytes: _parsingBuffer.bytes
                                                       length: _parsingBuffer.length
                                                     encoding: _connectionState.stringEncoding];
  
  // This is a heuristic. I've made it as tight as I can to avoid false positives.
  
  if ([promptCandidate hasSuffix: @" "])
  {
    promptCandidate = [promptCandidate substringToIndex: promptCandidate.length - 1];
    
    if ([[NSCharacterSet characterSetWithCharactersInString: @">?|:)]"] characterIsMember:
         [promptCandidate characterAtIndex: promptCandidate.length - 1]])
      [self useBufferedDataAsPrompt];
  }
}

- (void) sendPreprocessedDataToSocket
{
  if (_preprocessingBuffer.length > 0)
  {
    [self.delegate writeDataToSocket: _preprocessingBuffer];
    [_preprocessingBuffer setData: [NSData data]];
  }
}

- (void) useBufferedDataAsPrompt
{
  if (_parsingBuffer.length > 0)
  {
    [self.delegate displayDataAsPrompt: _parsingBuffer];
    [_parsingBuffer setData: [NSData data]];
  }
}

@end
