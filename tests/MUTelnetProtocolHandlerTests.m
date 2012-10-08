//
// MUTelnetProtocolHandlerTests.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTelnetProtocolHandlerTests.h"

#import "MUProtocolStack.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetConstants.h"

@interface MUTelnetProtocolHandlerTests (Private)

- (void) assertData: (NSData *) data hasBytesWithZeroTerminator: (const char *) bytes;
- (void) confirmTelnetWithDontEcho;
- (void) parseBytesWithZeroTerminator: (const uint8_t *) bytes;
- (void) parseCString: (const char *) string;
- (void) resetTest;
- (void) simulateDo: (uint8_t) option;
- (void) simulateIncomingSubnegotation: (const uint8_t *) payload length: (unsigned) payloadLength;
- (void) simulateWill: (uint8_t) option;

@end

#pragma mark -

@implementation MUTelnetProtocolHandlerTests

- (void) setUp
{
  [self resetTest];
}

- (void) tearDown
{
  return;
}

- (void) testIACEscapedInData
{
  uint8_t bytes[] = {MUTelnetInterpretAsCommand};
  NSData *data = [NSData dataWithBytes: bytes length: 1];
  NSData *preprocessedData = [protocolStack preprocessOutputData: data];
  
  const char expectedBytes[] = {MUTelnetInterpretAsCommand, MUTelnetInterpretAsCommand, 0};
  [self assertData: preprocessedData hasBytesWithZeroTerminator: expectedBytes];
}

- (void) testTelnetNotSentWhenNotConfirmed
{
  [self resetTest];
  [protocolHandler enableOptionForUs: 0];
  [protocolHandler enableOptionForHim: 0];
  [protocolHandler disableOptionForUs: 0];
  [protocolHandler disableOptionForHim: 0];
  [self assert: mockSocketData equals: [NSData data] message: @"telnet was written"];
}

- (void) testParsePlainText
{
  [self parseCString: "foo"];
  [self assertData: parsedData hasBytesWithZeroTerminator: "foo"];
}

- (void) testParseCRIACIAC
{
  uint8_t bytes[4] = {'\r', MUTelnetInterpretAsCommand, MUTelnetInterpretAsCommand, 0};
  [self parseCString: (const char *) bytes];
  [self assertData: parsedData hasBytesWithZeroTerminator: (const char *) bytes + 2];
}

- (void) testParseCRCRLF
{
  [self parseCString: "\r\r\n"];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\n"];
}

- (void) testParseCRCRNUL
{
  [protocolStack parseInputData: [NSData dataWithBytes: "\r\r\0" length: 3]];
  [protocolStack flushBufferedData];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\r"];
}

- (void) testParseCRLF
{
  [self parseCString: "\r\n"];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\n"];
}

- (void) testParseCRNUL
{
  [protocolStack parseInputData: [NSData dataWithBytes: "\r\0" length: 2]];
  [protocolStack flushBufferedData];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\r"];
}

- (void) testParseCRSomethingElse
{
  uint8_t bytes[2] = {'\r', 0};
  
  for (unsigned i = 1; i < UINT8_MAX; i++)
  {
    if (i == '\n' || i == '\r')
      continue;
    bytes[1] = i;
    [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 2]];
    [protocolStack flushBufferedData];
    [self assert: parsedData equals: [NSData dataWithBytes: bytes + 1 length: 1]];
    [self resetTest];
  }
}

- (void) testParseCRWithSomeTelnetThrownIn
{
  uint8_t bytes[4] = {'\r', MUTelnetInterpretAsCommand, MUTelnetNoOperation, 0};
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 4]];
  [protocolStack flushBufferedData];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\r"];
}

- (void) testParseLF
{
  [self parseCString: "\n"];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\n"];
}

- (void) testParseLFCRLFCR
{
  [self parseCString: "\n\r\n\r"];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\n\n"];
}

- (void) testParseLFCRNUL
{
  [protocolStack parseInputData: [NSData dataWithBytes: "\n\r\0" length: 3]];
  [protocolStack flushBufferedData];
  [self assertData: parsedData hasBytesWithZeroTerminator: "\n\r"];
}

- (void) testSubnegotiationPutsNothingInReadBuffer
{
  uint8_t bytes[9] = {MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTerminalType, MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 9]];
  [self assertUInteger: [parsedData length] equals: 0];
}

- (void) testSubnegotiationStrippedFromText
{
  uint8_t bytes[13] = {'a', 'b', MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTerminalType, MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation, 'c', 'd'};
  
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 13]];
  [protocolStack flushBufferedData];
  
  uint8_t expectedBytes[4] = {'a', 'b', 'c', 'd'};
  [self assert: parsedData equals: [NSData dataWithBytes: expectedBytes length: 4]];
}

#pragma mark - Telnet options

- (void) testDoSuppressGoAhead
{
  [self simulateDo: MUTelnetOptionSuppressGoAhead];
  [self assertTrue: [protocolHandler optionYesForUs: MUTelnetOptionSuppressGoAhead]];
}

- (void) testWillSuppressGoAhead
{
  [self simulateWill: MUTelnetOptionSuppressGoAhead];
  [self assertTrue: [protocolHandler optionYesForHim: MUTelnetOptionSuppressGoAhead]];
}

- (void) testGoAhead
{
  [self confirmTelnetWithDontEcho];
  
  NSData *preprocessedData = [protocolStack preprocessOutputData: [NSData data]];
  
  const char bytes[] = {MUTelnetInterpretAsCommand, MUTelnetGoAhead, 0};
  [self assertData: preprocessedData hasBytesWithZeroTerminator: bytes];
}

- (void) testSuppressedGoAhead
{
  [protocolHandler enableOptionForUs: MUTelnetOptionSuppressGoAhead];
  [self simulateDo: MUTelnetOptionSuppressGoAhead];
  
  NSData *preprocessedData = [protocolStack preprocessOutputData: [NSData data]];
  [self assertUInteger: [preprocessedData length] equals: 0];
}

- (void) testDoTerminalType
{
  [self simulateDo: MUTelnetOptionTerminalType];
  [self assertTrue: [protocolHandler optionYesForUs: MUTelnetOptionTerminalType]];
}

- (void) testRefuseWillTerminalType
{
  [self simulateWill: MUTelnetOptionTerminalType];
  [self assertFalse: [protocolHandler optionYesForHim: MUTelnetOptionTerminalType]];
}

- (void) testTerminalType
{
  [self simulateDo: MUTelnetOptionTerminalType];
  
  const uint8_t terminalTypeRequest[2] = {MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend};
  
  const uint8_t koanReply[10] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'K', 'O', 'A', 'N', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  const uint8_t unknownReply[13] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'U', 'N', 'K', 'N', 'O', 'W', 'N', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: koanReply length: 10]];
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: unknownReply length: 13]];
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: unknownReply length: 13]];
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: koanReply length: 10]];
}

- (void) testDoCharset
{
  [self simulateDo: MUTelnetOptionCharset];
  [self assertTrue: [protocolHandler optionYesForUs: MUTelnetOptionCharset]];
}

- (void) testWillCharset
{
  [self simulateWill: MUTelnetOptionCharset];
  [self assertTrue: [protocolHandler optionYesForHim: MUTelnetOptionCharset]];
}

- (void) testCharsetUTF8Accepted
{
  [self simulateWill: MUTelnetOptionTransmitBinary];
  [self simulateDo: MUTelnetOptionTransmitBinary];
  [self simulateWill: MUTelnetOptionCharset];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[8] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'U', 'T', 'F', '-', '8'};
  const uint8_t charsetReply[11] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'U', 'T', 'F', '-', '8', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: charsetRequest length: 8];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 11]];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSUTF8StringEncoding];
}

- (void) testCharsetLatin1Accepted
{
  [self simulateWill: MUTelnetOptionTransmitBinary];
  [self simulateDo: MUTelnetOptionTransmitBinary];
  [self simulateWill: MUTelnetOptionCharset];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[13] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'I', 'S', 'O', '-', '8', '8', '5', '9', '-', '1'};
  const uint8_t charsetReply[16] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'I', 'S', 'O', '-', '8', '8', '5', '9', '-', '1', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: charsetRequest length: 13];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 16]];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSISOLatin1StringEncoding];
}

- (void) testCharsetRejected
{
  [self simulateWill: MUTelnetOptionTransmitBinary];
  [self simulateDo: MUTelnetOptionTransmitBinary];
  [self simulateWill: MUTelnetOptionCharset];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[10] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'I', 'N', 'V', 'A', 'L', 'I', 'D'};
  const uint8_t charsetReply[6] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetRejected, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: charsetRequest length: 10];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 6]];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSASCIIStringEncoding];
}

- (void) testCharsetNonStandardBehavior
{
  [self simulateDo: MUTelnetOptionCharset];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[8] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'U', 'T', 'F', '-', '8'};
  const uint8_t charsetReply[17] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'U', 'T', 'F', '-', '8', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation, MUTelnetInterpretAsCommand, MUTelnetWill, MUTelnetOptionTransmitBinary, MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTransmitBinary};
  
  [mockSocketData setData: [NSData data]];
  [self simulateIncomingSubnegotation: charsetRequest length: 8];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 17]];
  
  [self assertUInteger: protocolHandler.connectionState.stringEncoding equals: NSUTF8StringEncoding];
}

- (void) testDoEndOfRecord
{
  [self simulateDo: MUTelnetOptionEndOfRecord];
  [self assertTrue: [protocolHandler optionYesForUs: MUTelnetOptionEndOfRecord]];
}

- (void) testWillEndOfRecord
{
  [self simulateWill: MUTelnetOptionEndOfRecord];
  [self assertTrue: [protocolHandler optionYesForHim: MUTelnetOptionEndOfRecord]];
}

- (void) testEndOfRecord
{
  [self simulateDo: MUTelnetOptionSuppressGoAhead];
  
  NSData *preprocessedData = [protocolStack preprocessOutputData: [NSData data]];
  [self assertUInteger: [preprocessedData length] equals: 0];
  
  [self simulateDo: MUTelnetOptionEndOfRecord];
  
  preprocessedData = [protocolStack preprocessOutputData: [NSData data]];
  
  uint8_t expectedBytes[2] = {MUTelnetInterpretAsCommand, MUTelnetEndOfRecord};
  [self assert: preprocessedData equals: [NSData dataWithBytes: expectedBytes length: 2]];
}

#pragma mark - MUProtocolStackDelegate protocol

- (void) displayDataAsText: (NSData *) data
{
  [parsedData appendData: data];
}

- (void) displayDataAsPrompt: (NSData *) data
{
  return;
}

#pragma mark - MUTelnetProtocolHandlerDelegate protocol

- (void) log: (NSString *) message arguments: (va_list) args
{
  return;
}

- (void) writeDataToSocket: (NSData *) data
{
  [mockSocketData appendData: data];
}

@end

#pragma mark -

@implementation MUTelnetProtocolHandlerTests (Private)

- (void) assertData: (NSData *) data hasBytesWithZeroTerminator: (const char *) bytes
{
  [self assert: data equals: [NSData dataWithBytes: bytes length: strlen (bytes)]];
}

- (void) confirmTelnetWithDontEcho
{
  uint8_t bytes[3] = {MUTelnetInterpretAsCommand, MUTelnetDont, MUTelnetOptionEcho};
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 3]];
}

- (void) parseBytesWithZeroTerminator: (const uint8_t *) bytes
{
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: strlen ((const char *) bytes)]];
  [protocolStack flushBufferedData];
}

- (void) parseCString: (const char *) string
{
  [self parseBytesWithZeroTerminator: (const uint8_t *) string];
}

- (void) resetTest
{

  MUMUDConnectionState *connectionState = [MUMUDConnectionState connectionState];
  
  protocolStack = [[MUProtocolStack alloc] initWithConnectionState: connectionState];
  [protocolStack setDelegate: self];
  
  protocolHandler = [MUTelnetProtocolHandler protocolHandlerWithStack: protocolStack connectionState: connectionState];
  [protocolHandler setDelegate: self];
  
  [protocolStack addByteProtocol: protocolHandler];
  
  
  parsedData = [[NSMutableData alloc] initWithCapacity: 64];
  
  
  mockSocketData = [[NSMutableData alloc] initWithCapacity: 64];
}

- (void) simulateDo: (uint8_t) option
{
  const uint8_t doRequest[] = {MUTelnetInterpretAsCommand, MUTelnetDo, option};
  [protocolStack parseInputData: [NSData dataWithBytes: doRequest length: 3]];
}

- (void) simulateIncomingSubnegotation: (const uint8_t *) payload length: (unsigned) payloadLength
{
  const uint8_t header[] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation};
  const uint8_t footer[] = {MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  NSMutableData *data = [NSMutableData data];
  [data appendBytes: header length: 2];
  [data appendBytes: payload length: payloadLength];
  [data appendBytes: footer length: 2];
  [protocolStack parseInputData: data];
}

- (void) simulateWill: (uint8_t) option
{
  const uint8_t willRequest[] = {MUTelnetInterpretAsCommand, MUTelnetWill, option};
  [protocolStack parseInputData: [NSData dataWithBytes: willRequest length: 3]];
}

@end
