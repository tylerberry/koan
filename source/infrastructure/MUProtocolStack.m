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

@end

#pragma mark -

@implementation MUProtocolStack
{
  MUMUDConnectionState *_connectionState;

  NSMutableArray *_mutableProtocolHandlers;
  NSMutableData *_parsedInputBuffer;
  NSMutableData *_preprocessedOutputBuffer;
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
    if (_connectionState.allowCodePage437Substitution
        && _connectionState.stringEncoding == NSASCIIStringEncoding)
      string = [string stringWithCodePage437Substitutions];

    [self.delegate appendStringToLineBuffer: string];

    [_parsedInputBuffer replaceBytesInRange: NSMakeRange (0, _parsedInputBuffer.length) withBytes: NULL length: 0];
  }
}

- (void) maybeUseBufferedDataAsPrompt
{
  [self flushBufferedData];
  [self.delegate maybeDisplayBufferedStringAsPrompt];
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
  [self flushBufferedData];
  [self.delegate displayBufferedStringAsPrompt];
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

- (void) reset
{
  for (MUProtocolHandler *protocolHandler in self.protocolHandlers)
  {
    [protocolHandler reset];
  }
}

- (void) sendPreprocessedData
{
  [self _sendPreprocessedDataToSocket];
}

#pragma mark - Private methods

- (void) _sendCompleteLineToDelegate
{
  [self flushBufferedData];
  [self.delegate displayBufferedStringAsText];
}

- (void) _sendPreprocessedDataToSocket
{
  if (_preprocessedOutputBuffer.length > 0)
  {
    [self.delegate writeDataToSocket: _preprocessedOutputBuffer];
    [_preprocessedOutputBuffer replaceBytesInRange: NSMakeRange (0, _preprocessedOutputBuffer.length)
                                         withBytes: NULL
                                            length: 0];
  }
}

@end
