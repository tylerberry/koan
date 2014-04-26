//
// MUProtocolStack.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolStack.h"

#import "NSString+CodePage437.h"
#import "MUProtocolHandler.h"

@interface MUProtocolStack ()

- (void) _sendCompleteLineToDelegate;
- (void) _sendPreprocessedDataToSocket;
- (void) _useBufferedDataAsPrompt;

@end

#pragma mark -

@implementation MUProtocolStack
{
  MUMUDConnectionState *_connectionState;

  NSMutableArray *_mutableProtocolHandlers;
  NSMutableData *_parsedInputBuffer;
  NSMutableData *_preprocessedOutputBuffer;
  NSMutableAttributedString *_lineBuffer;
}

@dynamic protocolHandlers;

- (id) initWithConnectionState: (MUMUDConnectionState *) connectionState
{
  if (!(self = [super init]))
    return nil;
  
  _connectionState = connectionState;
  
  _mutableProtocolHandlers = [[NSMutableArray alloc] init];
  _parsedInputBuffer = [[NSMutableData alloc] init];
  _preprocessedOutputBuffer = [[NSMutableData alloc] init];
  _lineBuffer = [[NSMutableAttributedString alloc] init];
  
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

- (void) deleteLastBufferedCharacter
{
  // At present, this is a destructive implementation of backspace and/or IAC EC.

  if (_parsedInputBuffer.length > 0)
  {
    [_parsedInputBuffer replaceBytesInRange: NSMakeRange (_parsedInputBuffer.length - 1, 1)
                                  withBytes: NULL
                                     length: 0];
  }
}

- (void) flushBufferedData
{
  if (_parsedInputBuffer.length > 0)
  {
    NSString *string = [[NSString alloc] initWithData: _parsedInputBuffer encoding: _connectionState.stringEncoding];

    // This is a pseudo-encoding: if we are using ASCII, substitute in CP437 characters.
    if (_connectionState.stringEncoding == NSASCIIStringEncoding)
      string = [string stringWithCodePage437Substitutions];

    [_lineBuffer appendAttributedString: [[NSAttributedString alloc] initWithString: string
                                                                             attributes: nil]];

    _parsedInputBuffer.data = [NSData data];
  }
}

- (void) maybeUseBufferedDataAsPrompt
{
  if (_connectionState.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyTinyMUSH) // TinyMUSH does not use prompts.
    return;                                                                         // PennMUSH does, though.
  
  NSString *promptCandidate = [[NSString alloc] initWithBytes: _parsedInputBuffer.bytes
                                                       length: _parsedInputBuffer.length
                                                     encoding: _connectionState.stringEncoding];
  
  // This is a heuristic. I've made it as tight as I can to avoid false positives.
  
  if ([promptCandidate hasSuffix: @" "])
  {
    promptCandidate = [promptCandidate substringToIndex: promptCandidate.length - 1];

    NSCharacterSet *promptCharacterSet = [NSCharacterSet characterSetWithCharactersInString: @">?|:)]"];

    if ([promptCharacterSet characterIsMember: [promptCandidate characterAtIndex: promptCandidate.length - 1]])
      [self _useBufferedDataAsPrompt];
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
  
  [self _sendPreprocessedDataToSocket];
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
  [self _useBufferedDataAsPrompt];
}

- (void) parseByte: (uint8_t) byte
{
  [_parsedInputBuffer appendBytes: &byte length: 1];
    
  if (byte == '\n')
    [self _sendCompleteLineToDelegate];
}

- (void) preprocessByte: (uint8_t) byte
{
  [_preprocessedOutputBuffer appendBytes: &byte length: 1];
}

- (void) preprocessFooterData: (NSData *) data
{
  [_preprocessedOutputBuffer appendData: data];
}

- (void) sendPreprocessedData
{
  [self _sendPreprocessedDataToSocket];
}

#pragma mark - Private methods

- (void) _sendCompleteLineToDelegate
{
  [self flushBufferedData];

  if (_lineBuffer.length > 0)
  {
    [self.delegate displayAttributedStringAsText: _lineBuffer];
    [_lineBuffer deleteCharactersInRange: NSMakeRange (0, _lineBuffer.length)];
  }
}

- (void) _sendPreprocessedDataToSocket
{
  if (_preprocessedOutputBuffer.length > 0)
  {
    [self.delegate writeDataToSocket: _preprocessedOutputBuffer];
    _preprocessedOutputBuffer.data = [NSData data];
  }
}

- (void) _useBufferedDataAsPrompt
{
  if (_lineBuffer.length > 0)
  {
    [self.delegate displayAttributedStringAsPrompt: _lineBuffer];
    [_lineBuffer deleteCharactersInRange: NSMakeRange (0, _lineBuffer.length)];
  }
}

@end
