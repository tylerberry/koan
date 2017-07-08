//
// MUTelnetProtocolHandlerTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUProtocolStack.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetConstants.h"
#import "MUTelnetProtocolHandler.h"

@interface MUTelnetProtocolHandlerTests : XCTestCase <MUProtocolStackDelegate, MUTelnetProtocolHandlerDelegate>

- (void) _assertData: (NSData *) data hasBytesWithZeroTerminator: (const char *) bytes;
- (void) _sendMockSocketData;
- (void) _confirmTelnetWithDontEcho;
- (void) _parseCString: (const char * const) string;
- (void) _parseData: (NSData *) data;
- (void) _parseString: (NSString *) string;
- (void) _resetTest;
- (void) _simulateDo: (uint8_t) option;
- (void) _simulateIncomingSubnegotation: (const uint8_t *) payload length: (unsigned) payloadLength;
- (void) _simulateWill: (uint8_t) option;

@end

#pragma mark -

@implementation MUTelnetProtocolHandlerTests
{
  MUMUDConnectionState *_connectionState;
  MUProtocolStack *_protocolStack;
  MUTelnetProtocolHandler *_protocolHandler;
  NSMutableData *_mockSocketData;
  NSMutableAttributedString *_parsedString;
}

- (void) setUp
{
  [super setUp];
  [self _resetTest];
}

- (void) tearDown
{
  [super tearDown];
}

- (void) testIACEscapedInData
{
  uint8_t bytes[] = {MUTelnetInterpretAsCommand};
  NSData *data = [NSData dataWithBytes: bytes length: 1];
  
  [_protocolStack preprocessOutputData: data];
  
  const char expectedBytes[] = {MUTelnetInterpretAsCommand, MUTelnetInterpretAsCommand, 0};
  [self _assertData: _mockSocketData hasBytesWithZeroTerminator: expectedBytes];
}

- (void) testTelnetNotSentWhenNotConfirmed
{
  [self _resetTest];
  [_protocolHandler enableOptionForUs: 0];
  [_protocolHandler enableOptionForHim: 0];
  [_protocolHandler disableOptionForUs: 0];
  [_protocolHandler disableOptionForHim: 0];
  XCTAssertEqualObjects (_mockSocketData, [NSData data], @"telnet was written");
}

- (void) testParsePlainText
{
  [self _parseString: @"foo"];
  XCTAssertEqualObjects (_parsedString.string, @"foo");
}

- (void) testParseCRIACIAC
{
  uint8_t bytes[4] = {'\r', MUTelnetInterpretAsCommand, MUTelnetInterpretAsCommand, 0};

  [self _parseCString: (const char *) bytes];
  XCTAssertEqualObjects (_parsedString.string, [NSString stringWithCString: "\xff" encoding: NSASCIIStringEncoding]);
}

- (void) testParseCRCRLF
{
  [self _parseString: @"\r\r\n"];
  XCTAssertEqualObjects (_parsedString.string, @"\n");
}

- (void) testParseCRCRNUL
{
  [self _parseData: [NSData dataWithBytes: "\r\r\0" length: 3]];
  XCTAssertEqualObjects (_parsedString.string, @"");
}

- (void) testParseCRLF
{
  [self _parseString: @"\r\n"];
  XCTAssertEqualObjects (_parsedString.string, @"\n");
}

- (void) testParseLFCR
{
  [self _parseString: @"\n\r"];
  XCTAssertEqualObjects (_parsedString.string, @"\n");
}

- (void) testParseCRNUL
{
  [self _parseData: [NSData dataWithBytes: "\r\0" length: 2]];
  XCTAssertEqualObjects (_parsedString.string, @"");
}

- (void) testCRNULOverwritesCharacters
{
  [self _parseData: [NSData dataWithBytes: "abcdefg\r\0pq" length: 11]];
  XCTAssertEqualObjects (_parsedString.string, @"pqcdefg");
}

- (void) testParseCRSomethingElse
{
  uint8_t bytes[2] = {'\r', 0};
  
  for (uint16_t i = 1; i < UINT8_MAX; i++)
  {
    if (i == '\n' || i == '\r')
      continue;

    bytes[1] = (uint8_t) i;
    [self _parseData: [NSData dataWithBytes: bytes length: 2]];

    XCTAssertEqualObjects (_parsedString.string,
                           [[NSString alloc] initWithData: [NSData dataWithBytes: bytes + 1 length: 1]
                                                 encoding: NSASCIIStringEncoding]);
    [self _resetTest];
  }
}

- (void) testParseCRWithSomeTelnetThrownIn
{
  uint8_t bytes[4] = {'\r', MUTelnetInterpretAsCommand, MUTelnetNoOperation, 0};
  [self _parseData: [NSData dataWithBytes: bytes length: 4]];
  XCTAssertEqualObjects (_parsedString.string, @"");
}

- (void) testParseLF
{
  [self _parseString: @"\n"];
  XCTAssertEqualObjects (_parsedString.string, @"\n");
}

- (void) testParseLFCRLFCR
{
  [self _parseString: @"\n\r\n\r"];
  XCTAssertEqualObjects (_parsedString.string, @"\n\n");
}

- (void) testParseLFCRNUL
{
  [_protocolStack parseInputData: [NSData dataWithBytes: "\n\r\0" length: 3]];
  [_protocolStack flushBufferedData];
  XCTAssertEqualObjects (_parsedString.string, @"\n");
}

- (void) testNVTEraseCharacter
{
  uint8_t bytes[4] = {'a', MUTelnetInterpretAsCommand, MUTelnetEraseCharacter, 'b'};

  [_protocolStack parseInputData: [NSData dataWithBytes: bytes length: 4]];
  [_protocolStack flushBufferedData];
  XCTAssertEqualObjects (_parsedString.string, @"b");
}

- (void) testSubnegotiationPutsNothingInReadBuffer
{
  uint8_t bytes[9] = {MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTerminalType, MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [_protocolStack parseInputData: [NSData dataWithBytes: bytes length: 9]];
  XCTAssertEqual (_parsedString.length, (NSUInteger) 0);
}

- (void) testSubnegotiationStrippedFromText
{
  uint8_t bytes[13] = {'a', 'b', MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTerminalType, MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation, 'c', 'd'};
  
  [self _parseData: [NSData dataWithBytes: bytes length: 13]];

  XCTAssertEqualObjects (_parsedString.string, @"abcd");
}

#pragma mark - Telnet options

- (void) testDoSuppressGoAhead
{
  [self _simulateDo: MUTelnetOptionSuppressGoAhead];
  XCTAssertTrue ([_protocolHandler optionEnabledForUs: MUTelnetOptionSuppressGoAhead]);
}

- (void) testWillSuppressGoAhead
{
  [self _simulateWill: MUTelnetOptionSuppressGoAhead];
  XCTAssertTrue ([_protocolHandler optionEnabledForHim: MUTelnetOptionSuppressGoAhead]);
}

- (void) testGoAhead
{
  [self _confirmTelnetWithDontEcho];
  _mockSocketData.data = [NSData data]; // Discard initial option negotiation.
  
  [_protocolStack preprocessOutputData: [NSData data]];
  
  const char bytes[] = {MUTelnetInterpretAsCommand, MUTelnetGoAhead, 0};
  [self _assertData: _mockSocketData hasBytesWithZeroTerminator: bytes];
}

- (void) testSuppressedGoAhead
{
  [_protocolHandler enableOptionForUs: MUTelnetOptionSuppressGoAhead];
  [self _simulateDo: MUTelnetOptionSuppressGoAhead];
  [self _sendMockSocketData];
  
  [_protocolStack preprocessOutputData: [NSData data]];
  XCTAssertEqual (_mockSocketData.length, (NSUInteger) 0);
}

- (void) testDoTerminalType
{
  [self _simulateDo: MUTelnetOptionTerminalType];
  XCTAssertTrue ([_protocolHandler optionEnabledForUs: MUTelnetOptionTerminalType]);
}

- (void) testRefuseWillTerminalType
{
  [self _simulateWill: MUTelnetOptionTerminalType];
  XCTAssertFalse ([_protocolHandler optionEnabledForHim: MUTelnetOptionTerminalType]);
}

- (void) testTerminalType
{
  [self _simulateDo: MUTelnetOptionTerminalType];
  
  const uint8_t terminalTypeRequest[2] = {MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend};
  
  const uint8_t koan256Reply[19] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'k', 'o', 'a', 'n', '-', '2', '5', '6', 'c', 'o', 'l', 'o', 'r', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  const uint8_t koanReply[10] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'k', 'o', 'a', 'n', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  const uint8_t unknownReply[13] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'u', 'n', 'k', 'n', 'o', 'w', 'n', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: koan256Reply length: 19], @"koan-256color");
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: koanReply length: 10], @"koan");
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: unknownReply length: 13], @"unknown");
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: unknownReply length: 13], @"unknown 2");
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: koan256Reply length: 19], @"wraparound");
}

- (void) testDoCharset
{
  [self _simulateDo: MUTelnetOptionCharset];
  XCTAssertTrue ([_protocolHandler optionEnabledForUs: MUTelnetOptionCharset]);
}

- (void) testWillCharset
{
  [self _simulateWill: MUTelnetOptionCharset];
  XCTAssertTrue ([_protocolHandler optionEnabledForHim: MUTelnetOptionCharset]);
}

- (void) testCharsetUTF8Accepted
{
  [self _simulateWill: MUTelnetOptionTransmitBinary];
  [self _simulateDo: MUTelnetOptionTransmitBinary];
  [self _simulateWill: MUTelnetOptionCharset];
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSASCIIStringEncoding);
  
  const uint8_t charsetRequest[8] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'U', 'T', 'F', '-', '8'};
  const uint8_t charsetReply[11] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'U', 'T', 'F', '-', '8', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: charsetRequest length: 8];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: charsetReply length: 11]);
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSUTF8StringEncoding);
}

- (void) testCharsetLatin1Accepted
{
  [self _simulateWill: MUTelnetOptionTransmitBinary];
  [self _simulateDo: MUTelnetOptionTransmitBinary];
  [self _simulateWill: MUTelnetOptionCharset];
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSASCIIStringEncoding);
  
  const uint8_t charsetRequest[13] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'I', 'S', 'O', '-', '8', '8', '5', '9', '-', '1'};
  const uint8_t charsetReply[16] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'I', 'S', 'O', '-', '8', '8', '5', '9', '-', '1', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: charsetRequest length: 13];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: charsetReply length: 16]);
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSISOLatin1StringEncoding);
}

- (void) testCharsetRejected
{
  [self _simulateWill: MUTelnetOptionTransmitBinary];
  [self _simulateDo: MUTelnetOptionTransmitBinary];
  [self _simulateWill: MUTelnetOptionCharset];
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSASCIIStringEncoding);
  
  const uint8_t charsetRequest[10] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'I', 'N', 'V', 'A', 'L', 'I', 'D'};
  const uint8_t charsetReply[6] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetRejected, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: charsetRequest length: 10];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: charsetReply length: 6]);
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSASCIIStringEncoding);
}

- (void) testCharsetNonStandardBehavior
{
  [self _simulateDo: MUTelnetOptionCharset];
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSASCIIStringEncoding);
  
  const uint8_t charsetRequest[8] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'U', 'T', 'F', '-', '8'};
  const uint8_t charsetReply[17] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'U', 'T', 'F', '-', '8', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation, MUTelnetInterpretAsCommand, MUTelnetWill, MUTelnetOptionTransmitBinary, MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTransmitBinary};
  
  _mockSocketData.data = [NSData data];
  [self _simulateIncomingSubnegotation: charsetRequest length: 8];
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: charsetReply length: 17]);
  
  XCTAssertEqual (_connectionState.stringEncoding, (NSStringEncoding) NSUTF8StringEncoding);
}

- (void) testDoEndOfRecord
{
  [self _simulateDo: MUTelnetOptionEndOfRecord];
  XCTAssertTrue ([_protocolHandler optionEnabledForUs: MUTelnetOptionEndOfRecord]);
}

- (void) testWillEndOfRecord
{
  [self _simulateWill: MUTelnetOptionEndOfRecord];
  XCTAssertTrue ([_protocolHandler optionEnabledForHim: MUTelnetOptionEndOfRecord]);
}

- (void) testEndOfRecord
{
  [self _simulateDo: MUTelnetOptionSuppressGoAhead];
  [self _sendMockSocketData];
  
  [_protocolStack preprocessOutputData: [NSData data]];
  XCTAssertEqual (_mockSocketData.length, (NSUInteger) 0);
  
  [self _simulateDo: MUTelnetOptionEndOfRecord];
  [self _sendMockSocketData];
  
  [_protocolStack preprocessOutputData: [NSData data]];
  
  uint8_t expectedBytes[2] = {MUTelnetInterpretAsCommand, MUTelnetEndOfRecord};
  XCTAssertEqualObjects (_mockSocketData, [NSData dataWithBytes: expectedBytes length: 2]);
}

#pragma mark - MUProtocolStackDelegate protocol

- (void) appendStringToLineBuffer: (NSString *) string
{
  [_parsedString appendAttributedString: [[NSAttributedString alloc] initWithString: string]];
}

- (void) displayBufferedStringAsText
{
  return;
}

- (void) displayBufferedStringAsPrompt
{
  return;
}

- (void) maybeDisplayBufferedStringAsPrompt
{
  return;
}

- (void) writeDataToSocket: (NSData *) data
{
  [_mockSocketData appendData: data];
}

#pragma mark - MUTelnetProtocolHandlerDelegate protocol

- (void) enableTLS
{
  return;
}

- (void) log: (NSString *) message arguments: (va_list) args
{
  return;
}

- (void) reportWindowSizeToServer
{
  return;
}

#pragma mark - Private methods

- (void) _assertData: (NSData *) data hasBytesWithZeroTerminator: (const char *) bytes
{
  XCTAssertEqualObjects (data, [NSData dataWithBytes: bytes length: strlen (bytes)]);
}

- (void) _confirmTelnetWithDontEcho
{
  uint8_t bytes[3] = {MUTelnetInterpretAsCommand, MUTelnetDont, MUTelnetOptionEcho};
  [_protocolStack parseInputData: [NSData dataWithBytes: bytes length: 3]];
}

- (void) _parseCString: (const char *) string
{
  [_protocolStack parseInputData: [NSData dataWithBytes: string length: strlen (string)]];
  [_protocolStack flushBufferedData];
}

- (void) _parseData: (NSData *) data
{
  [_protocolStack parseInputData: data];
  [_protocolStack flushBufferedData];
}

- (void) _parseString: (NSString *) string
{
  [_protocolStack parseInputData: [string dataUsingEncoding: NSASCIIStringEncoding]];
  [_protocolStack flushBufferedData];
}

- (void) _resetTest
{
  _connectionState = [[MUMUDConnectionState alloc] initWithCodebaseAnalyzerDelegate: nil];
  _connectionState.allowCodePage437Substitution = NO;
  
  _protocolStack = [[MUProtocolStack alloc] initWithConnectionState: _connectionState];
  _protocolStack.delegate = self;
  
  _protocolHandler = [MUTelnetProtocolHandler protocolHandlerWithConnectionState: _connectionState];
  _protocolHandler.delegate = self;
  
  [_protocolStack addProtocolHandler: _protocolHandler];
  
  _parsedString = [[NSMutableAttributedString alloc] init];
  _mockSocketData = [NSMutableData new];
}

- (void) _sendMockSocketData
{
  _mockSocketData.data = [NSData data];
}

- (void) _simulateDo: (uint8_t) option
{
  const uint8_t doRequest[] = {MUTelnetInterpretAsCommand, MUTelnetDo, option};
  [_protocolStack parseInputData: [NSData dataWithBytes: doRequest length: 3]];
}

- (void) _simulateIncomingSubnegotation: (const uint8_t *) payload length: (unsigned) payloadLength
{
  const uint8_t header[] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation};
  const uint8_t footer[] = {MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  NSMutableData *data = [NSMutableData data];
  [data appendBytes: header length: 2];
  [data appendBytes: payload length: payloadLength];
  [data appendBytes: footer length: 2];
  
  [_protocolStack parseInputData: data];
}

- (void) _simulateWill: (uint8_t) option
{
  const uint8_t willRequest[] = {MUTelnetInterpretAsCommand, MUTelnetWill, option};
  [_protocolStack parseInputData: [NSData dataWithBytes: willRequest length: 3]];
}

@end
