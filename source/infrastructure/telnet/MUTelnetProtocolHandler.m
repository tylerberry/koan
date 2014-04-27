//
// MUTelnetProtocolHandler.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUProtocolStack.h"
#import "MUTelnetStateMachine.h"
#import "MUWriteBuffer.h"

static NSArray *_acceptableCharsets;
static NSArray *_offerableCharsets;
static NSArray *_offerableTerminalTypes;

#pragma mark -

@interface MUTelnetProtocolHandler ()

- (void) _negotiateOptions;
- (void) _permitDoForOption: (uint8_t) option;
- (void) _permitWillForOption: (uint8_t) option;
- (void) _sendCommand: (uint8_t) command withByte: (uint8_t) byte;
- (void) _sendEscapedByte: (uint8_t) byte;

@end

#pragma mark -

@interface MUTelnetProtocolHandler (Subnegotiation)

- (void) _sendSubnegotiationWithBytes: (const uint8_t * const) payloadBytes length: (NSUInteger) payloadLength;
- (void) _sendSubnegotiationWithData: (NSData *) payloadData;

- (void) _handleCharsetSubnegotiation: (NSData *) subnegotiationData;
- (void) _sendCharsetAcceptedSubnegotiationForCharset: (NSString *) charset;
- (void) _sendCharsetRejectedSubnegotiation;
- (void) _sendCharsetRequestSubnegotiation;
- (void) _sendCharsetTTableRejectedSubnegotiation;
- (NSStringEncoding) _stringEncodingForName: (NSString *) encodingName;

- (void) _handleStartTLSSubnegotiation: (NSData *) subnegotiationData;
- (void) _sendStartTLSFollowsSubnegotiation;

- (void) _handleMCCPSubnegotiation: (NSData *) subnegotiationData version: (uint8_t) versionByte;

- (void) _handleMSSPSubnegotiation: (NSData *) subnegotiationData;
- (void) _logMSSPVariableData: (NSData *) variableData valueData: (NSData *) valueData;

- (void) _handleTerminalTypeSubnegotiation: (NSData *) subnegotiationData;
- (void) _sendTerminalTypeSubnegotiation;

@end

#pragma mark -

@implementation MUTelnetProtocolHandler
{
  MUTelnetStateMachine *_telnetStateMachine;
  MUMUDConnectionState *_connectionState;
  MUTelnetOption *_options[TELNET_OPTION_MAX + 1];

  NSMutableData *_subnegotiationBuffer;

  BOOL _receivedCarriageReturn;
  BOOL _sentOptionRequest;
}

+ (void) initialize
{
  _acceptableCharsets = @[@"UTF-8", @"ISO-8859-1", @"ISO_8859-1", @"ISO_8859-1:1987", @"ISO-IR-100", @"LATIN1", @"L1",
                         @"IBM819", @"CP819", @"CSISOLATIN1", @"US-ASCII", @"ASCII", @"ANSI_X3.4-1968", @"ISO-IR-6",
                         @"ANSI_X3.4-1986", @"ISO_646.IRV:1991", @"US", @"ISO646-US", @"IBM367", @"CP367", @"CSASCII"];
  
  _offerableCharsets = @[@"UTF-8", @"ISO-8859-1", @"US-ASCII"];

  _offerableTerminalTypes = @[@"koan-256color", @"koan", @"unknown", @"unknown"];
}

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithConnectionState: telnetConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;

  _telnetStateMachine = [MUTelnetStateMachine stateMachine];
  _connectionState = telnetConnectionState;
  
  _subnegotiationBuffer = [[NSMutableData alloc] initWithCapacity: 64];

  _receivedCarriageReturn = NO;
  _sentOptionRequest = NO;

  [self reset];
  return self;
}

- (void) disableOptionForHim: (uint8_t) option
{
  if (_telnetStateMachine.telnetConfirmed)
    [_options[option] disableHim];
}

- (void) disableOptionForUs: (uint8_t) option
{
  if (_telnetStateMachine.telnetConfirmed)
    [_options[option] disableUs];
}

- (void) enableOptionForHim: (uint8_t) option
{
  if (_telnetStateMachine.telnetConfirmed)
    [_options[option] enableHim];
}

- (void) enableOptionForUs: (uint8_t) option
{
  if (_telnetStateMachine.telnetConfirmed)
    [_options[option] enableUs];
}

- (BOOL) optionEnabledForHim: (uint8_t) option
{
  return _options[option].enabledForHim;
}

- (BOOL) optionEnabledForUs: (uint8_t) option
{
  return _options[option].enabledForUs;
}

- (void) reset
{
  OSAtomicTestAndClearBarrier (1, &_sentOptionRequest);

  for (uint8_t i = 0; i < TELNET_OPTION_MAX; i++)
    _options[i] = [[MUTelnetOption alloc] initWithOption: i delegate: self];

  [self _permitWillForOption: MUTelnetOptionEcho];

  [self _permitDoForOption: MUTelnetOptionTransmitBinary];
  [self _permitWillForOption: MUTelnetOptionTransmitBinary];

  [self _permitDoForOption: MUTelnetOptionSuppressGoAhead];
  [self _permitWillForOption: MUTelnetOptionSuppressGoAhead];

  [self _permitDoForOption: MUTelnetOptionTerminalType];

  [self _permitDoForOption: MUTelnetOptionEndOfRecord];
  [self _permitWillForOption: MUTelnetOptionEndOfRecord];

  [self _permitDoForOption: MUTelnetOptionNegotiateAboutWindowSize];

  [self _permitDoForOption: MUTelnetOptionCharset];
  [self _permitWillForOption: MUTelnetOptionCharset];

  //[self _permitDoForOption: MUTelnetOptionStartTLS]; // Disabled due to not working properly.

  [self _permitWillForOption: MUTelnetOptionMSSP];

  [self _permitWillForOption: MUTelnetOptionMCCP1];

  [self _permitWillForOption: MUTelnetOptionMCCP2];
}

- (void) _permitWillForOption: (uint8_t) option
{
  _options[option].permittedForHim = YES;
}

- (void) _permitDoForOption: (uint8_t) option
{
  _options[option].permittedForUs = YES;
}

- (BOOL) telnetConfirmed
{
  return _telnetStateMachine.telnetConfirmed;
}

#pragma mark - MUTelnetProtocolHandler protocol

- (void) bufferSubnegotiationByte: (uint8_t) byte
{
  [_subnegotiationBuffer appendBytes: &byte length: 1];
}

- (void) bufferTextByte: (uint8_t) byte
{
  if (_receivedCarriageReturn && byte != '\r')
  {
    _receivedCarriageReturn = NO;
    if (byte == '\0')
      PASS_ON_PARSED_BYTE ('\r');
    else
      PASS_ON_PARSED_BYTE (byte);
  } 
  else if (byte == '\r')
  {
    _receivedCarriageReturn = YES;
  }
  else
  {
    PASS_ON_PARSED_BYTE (byte);
  }
}

- (void) deleteLastBufferedCharacter
{
  [self.protocolStack deleteLastBufferedCharacter];
}

- (void) handleBufferedSubnegotiation
{
  if (_subnegotiationBuffer.length == 0)
  {
    [self log: @"  Telnet: Received zero-length subnegotiation."];
  }
  
  const uint8_t *bytes = _subnegotiationBuffer.bytes;
  
  switch (bytes[0])
  {
    case MUTelnetOptionTerminalType:
      [self _handleTerminalTypeSubnegotiation: _subnegotiationBuffer];
      break;
      
    case MUTelnetOptionCharset:
      [self _handleCharsetSubnegotiation: _subnegotiationBuffer];
      break;
      
    case MUTelnetOptionStartTLS:
      [self _handleStartTLSSubnegotiation: _subnegotiationBuffer];
      break;
      
    case MUTelnetOptionMSSP:
      [self _handleMSSPSubnegotiation: _subnegotiationBuffer];
      break;
      
    case MUTelnetOptionMCCP1:
      [self _handleMCCPSubnegotiation: _subnegotiationBuffer version: MUTelnetOptionMCCP1];
      break;
      
    case MUTelnetOptionMCCP2:
      [self _handleMCCPSubnegotiation: _subnegotiationBuffer version: MUTelnetOptionMCCP2];
      break;
      
    default:
      [self log: @"Unknown subnegotation for option %@. [%@]",
       [MUTelnetOption optionNameForByte: bytes[0]], _subnegotiationBuffer];
      break;
  }
  
  _subnegotiationBuffer.data = [NSData data];
}

- (void) log: (NSString *) message, ...
{
  va_list args;
  va_start (args, message);
  
  [self.delegate log: message arguments: args];
  
  va_end (args);
}

- (void) receivedDo: (uint8_t) option
{
  [_options[option] receivedDo];
  
  if (option == MUTelnetOptionNegotiateAboutWindowSize)
  {
    _connectionState.shouldReportWindowSizeChanges = YES;
    [self.delegate reportWindowSizeToServer];
  }
  else if (option == MUTelnetOptionCharset)
  {
    [self _sendCharsetRequestSubnegotiation];
  }
  else if (option == MUTelnetOptionStartTLS)
  {
    //_connectionState.needsSingleByteSocketReads = YES;
    //[self sendStartTLSFollowsSubnegotiation];
  }
  
  [_connectionState.codebaseAnalyzer noteTelnetDo: option];
}

- (void) receivedDont: (uint8_t) option
{
  [_options[option] receivedDont];
  
  if (option == MUTelnetOptionNegotiateAboutWindowSize)
  {
    _connectionState.shouldReportWindowSizeChanges = NO;
  }

  [_connectionState.codebaseAnalyzer noteTelnetDont: option];
}

- (void) receivedWill: (uint8_t) option
{
  [_options[option] receivedWill];
  
  if (option == MUTelnetOptionEcho)
  {
    _connectionState.serverWillEcho = YES;
  }
  else if (option == MUTelnetOptionMCCP2)
  {
    _options[MUTelnetOptionMCCP1].permittedForHim = NO;
  }
  
  [_connectionState.codebaseAnalyzer noteTelnetWill: option];
}

- (void) receivedWont: (uint8_t) option
{
  [_options[option] receivedWont];
  
  if (option == MUTelnetOptionEcho)
    _connectionState.serverWillEcho = NO;
  
  [_connectionState.codebaseAnalyzer noteTelnetWont: option];
}

- (void) sendNAWSSubnegotiationWithNumberOfLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  if (!_connectionState.shouldReportWindowSizeChanges)
    return;
  
  uint8_t nawsSubnegotiationHeader[1] = {MUTelnetOptionNegotiateAboutWindowSize};
  
  NSMutableData *constructedData = [NSMutableData dataWithBytes: nawsSubnegotiationHeader length: 1];
  
  uint8_t width1 = (uint8_t) numberOfColumns / 255;
  uint8_t width0 = (uint8_t) numberOfColumns % 255;
  uint8_t height1 = (uint8_t) numberOfLines / 255;
  uint8_t height0 = (uint8_t) numberOfLines % 255;
  
  [constructedData appendBytes: &width1 length: 1];
  if (width1 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &width1 length: 1];
  
  [constructedData appendBytes: &width0 length: 1];
  if (width0 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &width0 length: 1];
  
  [constructedData appendBytes: &height1 length: 1];
  if (height1 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &height1 length: 1];
  
  [constructedData appendBytes: &height0 length: 1];
  if (height0 == MUTelnetInterpretAsCommand)
    [constructedData appendBytes: &height0 length: 1];
  
  [self _sendSubnegotiationWithData: constructedData];
  [self log: @"    Sent: IAC SB %@ %d %d %d %d IAC SE.",
   [MUTelnetOption optionNameForByte: MUTelnetOptionNegotiateAboutWindowSize], width1, width0, height1, height0];
}

- (void) useBufferedDataAsPrompt
{
  [self notePromptMarker];
}

#pragma mark - MUProtocolHandler overrides

- (void) parseByte: (uint8_t) byte
{
  [_telnetStateMachine parse: byte forProtocolHandler: self];
  
  if (_telnetStateMachine.telnetConfirmed)
  {
    if (OSAtomicTestAndSetBarrier (1, &_sentOptionRequest) == 0)
    {
      [self _negotiateOptions];
    }
  }
}

- (void) preprocessByte: (uint8_t) byte
{
  if (byte == MUTelnetInterpretAsCommand)
    PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (byte);
}

- (void) preprocessFooterData: (NSData *) data
{
  NSMutableData *footerData = [NSMutableData dataWithData: data];
  
  if ([self optionEnabledForUs: MUTelnetOptionEndOfRecord])
  {
    uint8_t endOfRecordBytes[] = {MUTelnetInterpretAsCommand, MUTelnetEndOfRecord};
    [footerData appendBytes: &endOfRecordBytes length: 2];
  }
  
  if (_telnetStateMachine.telnetConfirmed
      && ![self optionEnabledForUs: MUTelnetOptionSuppressGoAhead]
      && !(_connectionState.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyPennMUSH
           || _connectionState.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyEvennia))
  {
    // Note the codebase-specific hacks here - some codebases react extremely poorly to IAC GA and either don't support
    // or refuse to negotiate SUPPRESS-GO-AHEAD.
    
    uint8_t goAheadBytes[] = {MUTelnetInterpretAsCommand, MUTelnetGoAhead};
    [footerData appendBytes: &goAheadBytes length: 2];
  } 
  
  PASS_ON_PREPROCESSED_FOOTER_DATA (footerData);
}

#pragma mark - MUTelnetOptionDelegate protocol

- (void) do: (uint8_t) option
{
  [self log: @"    Sent: IAC DO %@.", [MUTelnetOption optionNameForByte: option]];
  [self _sendCommand: MUTelnetDo withByte: option];
}

- (void) dont: (uint8_t) option
{
  [self log: @"    Sent: IAC DONT %@.", [MUTelnetOption optionNameForByte: option]];
  [self _sendCommand: MUTelnetDont withByte: option];
}

- (void) will: (uint8_t) option
{
  [self log: @"    Sent: IAC WILL %@.", [MUTelnetOption optionNameForByte: option]];
  [self _sendCommand: MUTelnetWill withByte: option];
}

- (void) wont: (uint8_t) option
{
  [self log: @"    Sent: IAC WONT %@.", [MUTelnetOption optionNameForByte: option]];
  [self _sendCommand: MUTelnetWont withByte: option];
}

#pragma mark - Private methods

- (void) _negotiateOptions
{
  [self enableOptionForUs: MUTelnetOptionSuppressGoAhead];
  
  // PennMUSH does not respond well to IAC GA, but it ignores
  // IAC WILL SGA.  If we send IAC DO SGA it will request that
  // we also IAC DO SGA, so that results in a good set of options.

  if (_connectionState.codebaseAnalyzer.codebaseFamily == MUCodebaseFamilyPennMUSH)
    [self enableOptionForHim: MUTelnetOptionSuppressGoAhead];
}

- (void) _sendCommand: (uint8_t) command withByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (command);
  PASS_ON_PREPROCESSED_BYTE (byte);
  [self sendPreprocessedData];
}

- (void) _sendEscapedByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (byte);
  [self sendPreprocessedData];
}

@end

#pragma mark -

@implementation MUTelnetProtocolHandler (Subnegotiation)

- (void) _sendSubnegotiationWithBytes: (const uint8_t * const) payloadBytes length: (NSUInteger) payloadLength
{
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (MUTelnetBeginSubnegotiation);
  
  for (NSUInteger i = 0; i < payloadLength; i++)
    PASS_ON_PREPROCESSED_BYTE (payloadBytes[i]);
  
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (MUTelnetEndSubnegotiation);
  
  [self sendPreprocessedData];
}

- (void) _sendSubnegotiationWithData: (NSData *) payloadData
{
  [self _sendSubnegotiationWithBytes: payloadData.bytes length: payloadData.length];
}

#pragma mark - CHARSET

- (void) _handleCharsetSubnegotiation: (NSData *) subnegotiationData
{
  const uint8_t *bytes = subnegotiationData.bytes;
  NSUInteger length = subnegotiationData.length;
  
  if (![self optionEnabledForHim: MUTelnetOptionCharset])
    [self log: @"  Telnet: Server sent %@ REQUEST without WILL %@.",
     [MUTelnetOption optionNameForByte: bytes[0]],
     [MUTelnetOption optionNameForByte: bytes[0]]];
  
  if (length == 1)
  {
    [self log: @"  Telnet: Invalid length of %u for %@ subnegotiation. [%@]",
     length,
     [MUTelnetOption optionNameForByte: bytes[0]],
     subnegotiationData];
    return;
  }
  
  switch (bytes[1])
  {
    case MUTelnetCharsetRequest:
    {
      NSUInteger byteOffset = 2;
      BOOL serverOfferedTranslationTable = NO;
      uint8_t translationTableVersion = 0;
      
      if (length == 2)
      {
        [self log: @"  Telnet: Invalid length of %u for %@ REQUEST subnegotiation. [%@]",
         length,
         [MUTelnetOption optionNameForByte: bytes[0]],
         subnegotiationData];
        return;
      }
      
      if (length > 10 && strncmp ((char *) bytes + 2, "[TTABLE]", 8) == 0)
      {
        serverOfferedTranslationTable = YES;
        
        byteOffset += strlen ("[TTABLE]");
        translationTableVersion = bytes[byteOffset++];
        if (translationTableVersion != 1)
          [self log: @"  Telnet: Invalid TTABLE version %u for %@ REQUEST subnegotiation. [%@]",
           [MUTelnetOption optionNameForByte: bytes[0]],
           subnegotiationData];
      }
      
      uint8_t separatorCharacter = bytes[byteOffset];
      NSString *separatorCharacterString = [[NSString alloc] initWithBytes: &separatorCharacter length: 1 encoding: NSASCIIStringEncoding];
      
      if (separatorCharacter == MUTelnetInterpretAsCommand)
        [self log: @"  Telnet: IAC used as separator in %@ REQUEST subnegotiation. [%@]",
         [MUTelnetOption optionNameForByte: bytes[0]],
         subnegotiationData];
      
      NSString *offeredCharsetsString = [[NSString alloc] initWithBytes: (bytes + byteOffset + 1)
                                                                 length: (length - byteOffset - 1)
                                                               encoding: NSASCIIStringEncoding];
      NSArray *offeredCharsets = [offeredCharsetsString componentsSeparatedByString: separatorCharacterString];
      
      if (serverOfferedTranslationTable)
        [self log: @"Received: IAC SB %@ REQUEST [TTABLE] %u <%@> IAC SE.",
         [MUTelnetOption optionNameForByte: bytes[0]], translationTableVersion,
         [offeredCharsets componentsJoinedByString: @" "]];
      else
        [self log: @"Received: IAC SB %@ REQUEST <%@> IAC SE.",
         [MUTelnetOption optionNameForByte: bytes[0]],
         [offeredCharsets componentsJoinedByString: @" "]];
      
      for (NSString *charset in offeredCharsets)
      {
        if ([_acceptableCharsets containsObject: charset])
        {
          _connectionState.stringEncoding = [self _stringEncodingForName: charset];
          [self _sendCharsetAcceptedSubnegotiationForCharset: charset];
          
          if (_connectionState.stringEncoding == NSASCIIStringEncoding)
          {
            [self disableOptionForUs: MUTelnetOptionTransmitBinary];
            [self disableOptionForHim: MUTelnetOptionTransmitBinary];
          }
          else
          {
            [self enableOptionForUs: MUTelnetOptionTransmitBinary];
            [self enableOptionForHim: MUTelnetOptionTransmitBinary];
          }
          return;
        }
      }
      
      [self _sendCharsetRejectedSubnegotiation];
      return;
    }
      
    case MUTelnetCharsetAccepted:
    {
      if (_connectionState.charsetNegotiationStatus != MUTelnetCharsetNegotiationActive)
      {
        [self log: @"  Telnet: Received %@ ACCEPTED subnegotiation, but no active negotiation in progress.", [MUTelnetOption optionNameForByte: bytes[0]]];
      }
      
      if (length == 2)
      {
        [self log: @"  Telnet: Invalid length of %u for %@ ACCEPTED subnegotiation. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
        return;
      }
      
      NSString *acceptedCharset = [[NSString alloc] initWithBytes: bytes + 2 length: length - 2 encoding: NSASCIIStringEncoding];
      
      _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
      
      if ([_acceptableCharsets containsObject: acceptedCharset])
      {
        _connectionState.stringEncoding = [self _stringEncodingForName: acceptedCharset];
        
        if (_connectionState.stringEncoding == NSASCIIStringEncoding)
        {
          [self disableOptionForUs: MUTelnetOptionTransmitBinary];
          [self disableOptionForHim: MUTelnetOptionTransmitBinary];
        }
        else
        {
          [self enableOptionForUs: MUTelnetOptionTransmitBinary];
          [self enableOptionForHim: MUTelnetOptionTransmitBinary];
        }
        
        [self log: @"Received: IAC SB %@ ACCEPTED %@ IAC SE.", [MUTelnetOption optionNameForByte: bytes[0]], acceptedCharset];
      }
      else
        [self log: @"  Telnet: Server sent %@ ACCEPTED subnegotiation for %@, which was not offered.", [MUTelnetOption optionNameForByte: bytes[0]], acceptedCharset];
      
      return;
    }
      
    case MUTelnetCharsetRejected:
      if (_connectionState.charsetNegotiationStatus == MUTelnetCharsetNegotiationInactive)
        [self log: @"  Telnet: Received %@ REJECTED subnegotiation, but no active negotiation in progress.", length, [MUTelnetOption optionNameForByte: bytes[0]]];
      
      _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
      
      if (length > 2)
        [self log: @"  Telnet: Invalid length of %u for %@ REJECTED subnegotiation. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      else
        [self log: @"Received: IAC SB %@ REJECTED IAC SE.", [MUTelnetOption optionNameForByte: bytes[0]]];
      return;
      
    case MUTelnetCharsetTTableIs:
      [self log: @"  Telnet: Received %@ TTABLE-IS subnegotiation without offering to accept a translation table. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      [self _sendCharsetTTableRejectedSubnegotiation];
      return;
      
    case MUTelnetCharsetTTableAck:
      [self log: @"  Telnet: Received %@ TTABLE-ACK subnegotiation without offering a translation table. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      return;
      
    case MUTelnetCharsetTTableNak:
      [self log: @"  Telnet: Received %@ TTABLE-NAK subnegotiation without offering a translation table. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      return;
      
    case MUTelnetCharsetTTableRejected:
      [self log: @"  Telnet: Received %@ TTABLE-REJECTED subnegotiation without offering a translation table. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      return;
      
    default:
      [self log: @"  Telnet: %u is an unsupported %@ subnegotiation request. [%@]", bytes[1], [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
  }
}

- (void) _sendCharsetAcceptedSubnegotiationForCharset: (NSString *) charset
{
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetAccepted};
  NSMutableData *charsetAcceptedData = [NSMutableData dataWithBytes: bytes length: 2];
  
  [charsetAcceptedData appendBytes: [charset cStringUsingEncoding: NSASCIIStringEncoding]
                            length: [charset lengthOfBytesUsingEncoding: NSASCIIStringEncoding]];
  
  if (_connectionState.charsetNegotiationStatus == MUTelnetCharsetNegotiationActive)
    _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationIgnoreRejected;
  else
    _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  
  [self _sendSubnegotiationWithData: charsetAcceptedData];
  [self log: @"    Sent: IAC SB %@ ACCEPTED %@ IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset], charset];
}

- (void) _sendCharsetRejectedSubnegotiation
{
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetRejected};
  NSMutableData *charsetRejectedData = [NSMutableData dataWithBytes: bytes length: 2];
  
  if (_connectionState.charsetNegotiationStatus == MUTelnetCharsetNegotiationActive)
    _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationIgnoreRejected;
  else
    _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  
  [self _sendSubnegotiationWithData: charsetRejectedData];
  [self log: @"    Sent: IAC SB %@ REJECTED IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset]];
}

- (void) _sendCharsetRequestSubnegotiation
{
  if (_connectionState.charsetNegotiationStatus == MUTelnetCharsetNegotiationActive)
    return;
  
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetRequest};
  NSMutableData *charsetRequestData = [NSMutableData dataWithBytes: bytes length: 2];
  
  for (NSString *charset in _offerableCharsets)
  {
    uint8_t separator = ';';
    [charsetRequestData appendBytes: &separator length: 1];
    [charsetRequestData appendBytes: [charset cStringUsingEncoding: NSASCIIStringEncoding]
                             length: [charset lengthOfBytesUsingEncoding: NSASCIIStringEncoding]];
  }
  
  _connectionState.charsetNegotiationStatus = MUTelnetCharsetNegotiationActive;
  
  [self _sendSubnegotiationWithData: charsetRequestData];
  [self log: @"    Sent: IAC SB %@ REQUEST <%@> IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset], [_offerableCharsets componentsJoinedByString: @" "]];
}

- (void) _sendCharsetTTableRejectedSubnegotiation
{
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetTTableRejected};
  NSMutableData *charsetRejectedData = [NSMutableData dataWithBytes: bytes length: 2];
  
  [self _sendSubnegotiationWithData: charsetRejectedData];
  [self log: @"    Sent: IAC SB %@ TTABLE-REJECTED IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset]];
}

- (NSStringEncoding) _stringEncodingForName: (NSString *) encodingName
{
  if ([encodingName caseInsensitiveCompare: @"UTF-8"] == NSOrderedSame)
    return NSUTF8StringEncoding;
  
  else if ([encodingName caseInsensitiveCompare: @"ISO-8859-1"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"ISO_8859-1"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"ISO_8859-1:1987"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"ISO-IR-100"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"LATIN1"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"L1"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"IBM819"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"CP819"] == NSOrderedSame
           || [encodingName caseInsensitiveCompare: @"CSISOLATIN1"] == NSOrderedSame)
    return NSISOLatin1StringEncoding;
  
  /*
   else if ([encodingName caseInsensitiveCompare: @"US-ASCII"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"ASCII"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"ANSI_X3.4-1968"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"ISO-IR-6"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"ANSI_X3.4-1986"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"ISO_646.IRV:1991"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"US"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"ISO646-US"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"IBM367"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"CP367"] == NSOrderedSame
   || [encodingName caseInsensitiveCompare: @"CSASCII"] == NSOrderedSame)
   return NSASCIIStringEncoding;
   */
  
  // There is no "invalid encoding" value, so default to NVT ASCII.
  else return NSASCIIStringEncoding;
}

#pragma mark - START-TLS

- (void) _handleStartTLSSubnegotiation: (NSData *) subnegotiationData
{
  const uint8_t *bytes = subnegotiationData.bytes;
  
  if (subnegotiationData.length != 2)
  {
    [self log: @"%@ irregularity: %@ subnegotiation length is not 2. [%@]",
     [MUTelnetOption optionNameForByte: bytes[0]], [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
    return;
  }
  
  if (bytes[1] != MUTelnetStartTLSFollows)
  {
    [self log: @"%@ irregularity: Second byte is not FOLLOWS. [%@]",
     [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
    return;
  }
  
  [self log: @"Received: IAC SB %@ FOLLOWS IAC SE.", [MUTelnetOption optionNameForByte: bytes[0]]];
  
  [self _sendStartTLSFollowsSubnegotiation];
  [self.delegate performSelector: @selector (enableTLS) withObject: nil afterDelay: 0.5];
}

- (void) _sendStartTLSFollowsSubnegotiation
{
  uint8_t tlsFollowsBytes[2] = {MUTelnetOptionStartTLS, MUTelnetStartTLSFollows};
  
  [self _sendSubnegotiationWithBytes: tlsFollowsBytes length: 2];
  [self log: @"    Sent: IAC SB %@ FOLLOWS IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionStartTLS]];
}

#pragma mark - MCCP

- (void) _handleMCCPSubnegotiation: (NSData *) subnegotiationData version: (uint8_t) versionByte
{
  const uint8_t *bytes = subnegotiationData.bytes;
  
  if (subnegotiationData.length != 1)
  {
    [self log: @"MCCP irregularity: %@ subnegotiation length is not 1. [%@]",
     [MUTelnetOption optionNameForByte: versionByte], subnegotiationData];
    return;
  }
  
  if (bytes[0] != versionByte)
  {
    [self log: @"MCCP irregularity: First byte is not %@. [%@]",
     [MUTelnetOption optionNameForByte: versionByte], subnegotiationData];
    return;
  }
  
  switch (versionByte)
  {
    case MUTelnetOptionMCCP1:
      [self log: @"Received: IAC SB %@ WILL SE.", [MUTelnetOption optionNameForByte: versionByte]];
      break;
      
    case MUTelnetOptionMCCP2:
      [self log: @"Received: IAC SB %@ IAC SE.", [MUTelnetOption optionNameForByte: versionByte]];
      break;
  }
  
  _connectionState.isIncomingStreamCompressed = YES;
}

#pragma mark - MSSP

- (void) _handleMSSPSubnegotiation: (NSData *) subnegotiationData
{
  const uint8_t *bytes = subnegotiationData.bytes;
  
  if (subnegotiationData.length == 1)
  {
    [self log: @"MSSP irregularity: %@ subnegotiation length of 1. [%@]", [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
    return;
  }
  
  if (bytes[1] != 1)
  {
    [self log: @"MSSP irregularity: First byte is not MSSP-VAR. [%@]", subnegotiationData];
    return;
  }
  
  NSMutableData *variableData = [NSMutableData data];
  NSMutableData *valueData = [NSMutableData data];
  BOOL readingValue = NO;
  
  [self log: @"Received: IAC SB %@ [] IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionMSSP]];
  
  for (unsigned i = 2; i < subnegotiationData.length; i++)
  {
    switch (bytes[i])
    {
      case 1:
        readingValue = NO;
        [self _logMSSPVariableData: variableData valueData: valueData];
        variableData.data = [NSMutableData data];
        valueData.data = [NSMutableData data];
        continue;
        
      case 2:
        readingValue = YES;
        continue;
        
      default:
        if (readingValue)
          [valueData appendBytes: bytes + i length: 1];
        else
          [variableData appendBytes: bytes + i length: 1];
    }
  }
  
  if (!readingValue)
  {
    [self log: @"MSSP irregularity: Mismatched number of MSSP-VAR and MSSP-VAL. [%@]", subnegotiationData];
    return;
  }
  
  [self _logMSSPVariableData: variableData valueData: valueData];
}

- (void) _logMSSPVariableData: (NSData *) variableData valueData: (NSData *) valueData
{
  NSString *variableString = [[NSString alloc] initWithData: variableData encoding: NSASCIIStringEncoding];
  NSString *valueString = [[NSString alloc] initWithData: valueData encoding: NSASCIIStringEncoding];
  
  [_connectionState.codebaseAnalyzer noteMSSPVariable: variableString value: valueString];
  [self log: @"    MSSP:   %@ = %@.", variableString, valueString];
}

#pragma mark - TERMINAL-TYPE

- (void) _handleTerminalTypeSubnegotiation: (NSData *) subnegotiationData
{
  const uint8_t *bytes = subnegotiationData.bytes;
  
  if (subnegotiationData.length != 2)
  {
    [self log: @"  Telnet: Invalid length of %u for %@ subnegotiation request. [%@]",
     subnegotiationData.length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
    return;
  }
  
  if (bytes[1] != MUTelnetTerminalTypeSend)
  {
    [self log: @"  Telnet: %u is not a known %@ subnegotiation request. [%@]", bytes[1], [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
    return;
  }
  
  [self log: @"Received: IAC SB %@ SEND IAC SE.", [MUTelnetOption optionNameForByte: bytes[0]]];
  [self _sendTerminalTypeSubnegotiation];
}

- (void) _sendTerminalTypeSubnegotiation
{
  uint8_t prefixBytes[] = {MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs};
  NSMutableData *terminalTypeData = [NSMutableData dataWithBytes: prefixBytes length: 2];
  
  NSString *terminalType = _offerableTerminalTypes[_connectionState.nextTerminalTypeIndex++];
  
  if (_connectionState.nextTerminalTypeIndex >= _offerableTerminalTypes.count)
    _connectionState.nextTerminalTypeIndex = 0;
  
  [terminalTypeData appendBytes: [terminalType cStringUsingEncoding: NSASCIIStringEncoding]
                         length: [terminalType lengthOfBytesUsingEncoding: NSASCIIStringEncoding]];
  
  [self _sendSubnegotiationWithData: terminalTypeData];
  [self log: @"    Sent: IAC SB %@ IS %@ IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionTerminalType], terminalType];
}

@end
