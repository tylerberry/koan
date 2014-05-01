//
// MUTelnetProtocolHandlerTests.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetProtocolHandlerTests.h"

#import "MUProtocolStack.h"
#import "MUMUDConnectionState.h"
#import "MUTelnetConstants.h"

@interface MUTelnetProtocolHandlerTests ()

- (void) assertData: (NSData *) data hasBytesWithZeroTerminator: (const char *) bytes;
- (void) sendMockSocketData;
- (void) confirmTelnetWithDontEcho;
- (void) parseCString: (const char * const) string;
- (void) parseData: (NSData *) data;
- (void) parseString: (NSString *) string;
- (void) resetTest;
- (void) simulateDo: (uint8_t) option;
- (void) simulateIncomingSubnegotation: (const uint8_t *) payload length: (unsigned) payloadLength;
- (void) simulateWill: (uint8_t) option;

@end

#pragma mark -

@implementation MUTelnetProtocolHandlerTests
{
  MUMUDConnectionState *connectionState;
  MUProtocolStack *protocolStack;
  MUTelnetProtocolHandler *protocolHandler;
  NSMutableData *mockSocketData;
  NSMutableAttributedString *parsedString;
}

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
  
  [protocolStack preprocessOutputData: data];
  
  const char expectedBytes[] = {MUTelnetInterpretAsCommand, MUTelnetInterpretAsCommand, 0};
  [self assertData: mockSocketData hasBytesWithZeroTerminator: expectedBytes];
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
  [self parseString: @"foo"];
  [self assert: parsedString.string equals: @"foo"];
}

- (void) testParseCRIACIAC
{
  uint8_t bytes[4] = {'\r', MUTelnetInterpretAsCommand, MUTelnetInterpretAsCommand, 0};

  [self parseCString: (const char *) bytes];
  [self assert: parsedString.string equals: [NSString stringWithCString: "\xff" encoding: NSASCIIStringEncoding]];
}

- (void) testParseCRCRLF
{
  [self parseString: @"\r\r\n"];
  [self assert: parsedString.string equals: @"\n"];
}

- (void) testParseCRCRNUL
{
  [self parseData: [NSData dataWithBytes: "\r\r\0" length: 3]];
  [self assert: parsedString.string equals: @"\r"];
}

- (void) testParseCRLF
{
  [self parseString: @"\r\n"];
  [self assert: parsedString.string equals: @"\n"];
}

- (void) testParseCRNUL
{
  [self parseData: [NSData dataWithBytes: "\r\0" length: 2]];
  [self assert: parsedString.string equals: @"\r"];
}

- (void) testParseCRSomethingElse
{
  uint8_t bytes[2] = {'\r', 0};
  
  for (uint16_t i = 1; i < UINT8_MAX; i++)
  {
    if (i == '\n' || i == '\r')
      continue;

    bytes[1] = (uint8_t) i;
    [self parseData: [NSData dataWithBytes: bytes length: 2]];

    [self assert: parsedString.string equals: [[NSString alloc] initWithData: [NSData dataWithBytes: bytes + 1 length: 1]
                                                                    encoding: NSASCIIStringEncoding]];
    [self resetTest];
  }
}

- (void) testParseCRWithSomeTelnetThrownIn
{
  uint8_t bytes[4] = {'\r', MUTelnetInterpretAsCommand, MUTelnetNoOperation, 0};
  [self parseData: [NSData dataWithBytes: bytes length: 4]];
  [self assert: parsedString.string equals: @"\r"];
}

- (void) testParseLF
{
  [self parseString: @"\n"];
  [self assert: parsedString.string equals: @"\n"];
}

- (void) testParseLFCRLFCR
{
  [self parseString: @"\n\r\n\r"];
  [self assert: parsedString.string equals: @"\n\n"];
}

- (void) testParseLFCRNUL
{
  [protocolStack parseInputData: [NSData dataWithBytes: "\n\r\0" length: 3]];
  [protocolStack flushBufferedData];
  [self assert: parsedString.string equals: @"\n\r"];
}

- (void) testNVTEraseCharacter
{
  uint8_t bytes[4] = {'a', MUTelnetInterpretAsCommand, MUTelnetEraseCharacter, 'b'};

  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 4]];
  [protocolStack flushBufferedData];
  [self assert: parsedString.string equals: @"b"];
}

- (void) testSubnegotiationPutsNothingInReadBuffer
{
  uint8_t bytes[9] = {MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTerminalType, MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 9]];
  [self assertUInteger: parsedString.length equals: 0];
}

- (void) testSubnegotiationStrippedFromText
{
  uint8_t bytes[13] = {'a', 'b', MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTerminalType, MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation, 'c', 'd'};
  
  [self parseData: [NSData dataWithBytes: bytes length: 13]];

  [self assert: parsedString.string equals: @"abcd"];
}

#pragma mark - Telnet options

- (void) testDoSuppressGoAhead
{
  [self simulateDo: MUTelnetOptionSuppressGoAhead];
  [self assertTrue: [protocolHandler optionEnabledForUs: MUTelnetOptionSuppressGoAhead]];
}

- (void) testWillSuppressGoAhead
{
  [self simulateWill: MUTelnetOptionSuppressGoAhead];
  [self assertTrue: [protocolHandler optionEnabledForHim: MUTelnetOptionSuppressGoAhead]];
}

- (void) testGoAhead
{
  [self confirmTelnetWithDontEcho];
  mockSocketData.data = [NSData data]; // Discard initial option negotiation.
  
  [protocolStack preprocessOutputData: [NSData data]];
  
  const char bytes[] = {MUTelnetInterpretAsCommand, MUTelnetGoAhead, 0};
  [self assertData: mockSocketData hasBytesWithZeroTerminator: bytes];
}

- (void) testSuppressedGoAhead
{
  [protocolHandler enableOptionForUs: MUTelnetOptionSuppressGoAhead];
  [self simulateDo: MUTelnetOptionSuppressGoAhead];
  [self sendMockSocketData];
  
  [protocolStack preprocessOutputData: [NSData data]];
  [self assertUInteger: mockSocketData.length equals: 0];
}

- (void) testDoTerminalType
{
  [self simulateDo: MUTelnetOptionTerminalType];
  [self assertTrue: [protocolHandler optionEnabledForUs: MUTelnetOptionTerminalType]];
}

- (void) testRefuseWillTerminalType
{
  [self simulateWill: MUTelnetOptionTerminalType];
  [self assertFalse: [protocolHandler optionEnabledForHim: MUTelnetOptionTerminalType]];
}

- (void) testTerminalType
{
  [self simulateDo: MUTelnetOptionTerminalType];
  
  const uint8_t terminalTypeRequest[2] = {MUTelnetOptionTerminalType, MUTelnetTerminalTypeSend};
  
  const uint8_t koan256Reply[19] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'k', 'o', 'a', 'n', '-', '2', '5', '6', 'c', 'o', 'l', 'o', 'r', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  const uint8_t koanReply[10] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'k', 'o', 'a', 'n', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  const uint8_t unknownReply[13] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs, 'u', 'n', 'k', 'n', 'o', 'w', 'n', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: koan256Reply length: 19] message: @"koan-256color"];
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: koanReply length: 10] message: @"koan"];
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: unknownReply length: 13] message: @"unknown"];
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: unknownReply length: 13] message: @"unknown 2"];
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: terminalTypeRequest length: 2];
  [self assert: mockSocketData equals: [NSData dataWithBytes: koan256Reply length: 19] message: @"wraparound"];
}

- (void) testDoCharset
{
  [self simulateDo: MUTelnetOptionCharset];
  [self assertTrue: [protocolHandler optionEnabledForUs: MUTelnetOptionCharset]];
}

- (void) testWillCharset
{
  [self simulateWill: MUTelnetOptionCharset];
  [self assertTrue: [protocolHandler optionEnabledForHim: MUTelnetOptionCharset]];
}

- (void) testCharsetUTF8Accepted
{
  [self simulateWill: MUTelnetOptionTransmitBinary];
  [self simulateDo: MUTelnetOptionTransmitBinary];
  [self simulateWill: MUTelnetOptionCharset];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[8] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'U', 'T', 'F', '-', '8'};
  const uint8_t charsetReply[11] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'U', 'T', 'F', '-', '8', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: charsetRequest length: 8];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 11]];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSUTF8StringEncoding];
}

- (void) testCharsetLatin1Accepted
{
  [self simulateWill: MUTelnetOptionTransmitBinary];
  [self simulateDo: MUTelnetOptionTransmitBinary];
  [self simulateWill: MUTelnetOptionCharset];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[13] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'I', 'S', 'O', '-', '8', '8', '5', '9', '-', '1'};
  const uint8_t charsetReply[16] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'I', 'S', 'O', '-', '8', '8', '5', '9', '-', '1', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: charsetRequest length: 13];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 16]];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSISOLatin1StringEncoding];
}

- (void) testCharsetRejected
{
  [self simulateWill: MUTelnetOptionTransmitBinary];
  [self simulateDo: MUTelnetOptionTransmitBinary];
  [self simulateWill: MUTelnetOptionCharset];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[10] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'I', 'N', 'V', 'A', 'L', 'I', 'D'};
  const uint8_t charsetReply[6] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetRejected, MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation};
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: charsetRequest length: 10];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 6]];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSASCIIStringEncoding];
}

- (void) testCharsetNonStandardBehavior
{
  [self simulateDo: MUTelnetOptionCharset];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSASCIIStringEncoding];
  
  const uint8_t charsetRequest[8] = {MUTelnetOptionCharset, MUTelnetCharsetRequest, ';', 'U', 'T', 'F', '-', '8'};
  const uint8_t charsetReply[17] = {MUTelnetInterpretAsCommand, MUTelnetBeginSubnegotiation, MUTelnetOptionCharset, MUTelnetCharsetAccepted, 'U', 'T', 'F', '-', '8', MUTelnetInterpretAsCommand, MUTelnetEndSubnegotiation, MUTelnetInterpretAsCommand, MUTelnetWill, MUTelnetOptionTransmitBinary, MUTelnetInterpretAsCommand, MUTelnetDo, MUTelnetOptionTransmitBinary};
  
  mockSocketData.data = [NSData data];
  [self simulateIncomingSubnegotation: charsetRequest length: 8];
  [self assert: mockSocketData equals: [NSData dataWithBytes: charsetReply length: 17]];
  
  [self assertUInteger: connectionState.stringEncoding equals: NSUTF8StringEncoding];
}

- (void) testDoEndOfRecord
{
  [self simulateDo: MUTelnetOptionEndOfRecord];
  [self assertTrue: [protocolHandler optionEnabledForUs: MUTelnetOptionEndOfRecord]];
}

- (void) testWillEndOfRecord
{
  [self simulateWill: MUTelnetOptionEndOfRecord];
  [self assertTrue: [protocolHandler optionEnabledForHim: MUTelnetOptionEndOfRecord]];
}

- (void) testEndOfRecord
{
  [self simulateDo: MUTelnetOptionSuppressGoAhead];
  [self sendMockSocketData];
  
  [protocolStack preprocessOutputData: [NSData data]];
  [self assertUInteger: mockSocketData.length equals: 0];
  
  [self simulateDo: MUTelnetOptionEndOfRecord];
  [self sendMockSocketData];
  
  [protocolStack preprocessOutputData: [NSData data]];
  
  uint8_t expectedBytes[2] = {MUTelnetInterpretAsCommand, MUTelnetEndOfRecord};
  [self assert: mockSocketData equals: [NSData dataWithBytes: expectedBytes length: 2]];
}

#pragma mark - MUProtocolStackDelegate protocol

- (void) appendStringToLineBuffer: (NSString *) string
{
  [parsedString appendAttributedString: [[NSAttributedString alloc] initWithString: string]];
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
  [mockSocketData appendData: data];
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

- (void) assertData: (NSData *) data hasBytesWithZeroTerminator: (const char *) bytes
{
  [self assert: data equals: [NSData dataWithBytes: bytes length: strlen (bytes)]];
}

- (void) confirmTelnetWithDontEcho
{
  uint8_t bytes[3] = {MUTelnetInterpretAsCommand, MUTelnetDont, MUTelnetOptionEcho};
  [protocolStack parseInputData: [NSData dataWithBytes: bytes length: 3]];
}

- (void) parseCString: (const char *) string
{
  [protocolStack parseInputData: [NSData dataWithBytes: string length: strlen (string)]];
  [protocolStack flushBufferedData];
}

- (void) parseData: (NSData *) data
{
  [protocolStack parseInputData: data];
  [protocolStack flushBufferedData];
}

- (void) parseString: (NSString *) string
{
  [protocolStack parseInputData: [string dataUsingEncoding: NSASCIIStringEncoding]];
  [protocolStack flushBufferedData];
}

- (void) resetTest
{
  connectionState = [[MUMUDConnectionState alloc] init];
  connectionState.allowCodePage437Substitution = NO;
  
  protocolStack = [[MUProtocolStack alloc] initWithConnectionState: connectionState];
  protocolStack.delegate = self;
  
  protocolHandler = [MUTelnetProtocolHandler protocolHandlerWithConnectionState: connectionState];
  protocolHandler.delegate = self;
  
  [protocolStack addProtocolHandler: protocolHandler];
  
  parsedString = [[NSMutableAttributedString alloc] init];
  mockSocketData = [NSMutableData new];
}

- (void) sendMockSocketData
{
  mockSocketData.data = [NSData data];
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
