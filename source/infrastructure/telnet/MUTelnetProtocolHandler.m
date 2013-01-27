//
// MUTelnetProtocolHandler.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTelnetProtocolHandler.h"
#import "MUProtocolHandlerSubclass.h"

#import "MUTelnetStateMachine.h"
#import "MUWriteBuffer.h"


static NSArray *offerableTerminalTypes;
static NSArray *acceptableCharsets;
static NSArray *offerableCharsets;

#pragma mark -

@interface MUTelnetProtocolHandler ()
{
  MUMUDConnectionState *_state;
}

- (void) forOption: (uint8_t) option allowWill: (BOOL) willValue allowDo: (BOOL) doValue;
- (void) initializeOptions;
- (void) negotiateOptions;
- (void) sendCommand: (uint8_t) command withByte: (uint8_t) byte;
- (void) sendEscapedByte: (uint8_t) byte;

@end

#pragma mark -

@interface MUTelnetProtocolHandler (Subnegotiation)

- (void) sendSubnegotiationWithBytes: (const uint8_t *) payloadBytes length: (NSUInteger) payloadLength;
- (void) sendSubnegotiationWithData: (NSData *) payloadData;

- (void) handleCharsetSubnegotiation: (NSData *) subnegotiationData;
- (void) sendCharsetAcceptedSubnegotiationForCharset: (NSString *) charset;
- (void) sendCharsetRejectedSubnegotiation;
- (void) sendCharsetRequestSubnegotiation;
- (void) sendCharsetTTableRejectedSubnegotiation;
- (NSStringEncoding) stringEncodingForName: (NSString *) encodingName;

- (void) handleMCCPSubnegotiation: (NSData *) subnegotiationData version: (uint8_t) versionByte;

- (void) handleMSSPSubnegotiation: (NSData *) subnegotiationData;
- (void) logMSSPVariableData: (NSData *) variableData valueData: (NSData *) valueData;

- (void) handleTerminalTypeSubnegotiation: (NSData *) subnegotiationData;
- (void) sendTerminalTypeSubnegotiation;

@end

#pragma mark -

@implementation MUTelnetProtocolHandler

+ (void) initialize
{
  offerableTerminalTypes = @[@"koan-256color", @"koan", @"unknown", @"unknown"];
  
  acceptableCharsets = @[@"UTF-8", @"ISO-8859-1", @"ISO_8859-1", @"ISO_8859-1:1987",
                        @"ISO-IR-100", @"LATIN1", @"L1", @"IBM819", @"CP819", @"CSISOLATIN1", @"US-ASCII", @"ASCII",
                        @"ANSI_X3.4-1968", @"ISO-IR-6", @"ANSI_X3.4-1986", @"ISO_646.IRV:1991", @"US", @"ISO646-US",
                        @"IBM367", @"CP367", @"CSASCII"];
  
  offerableCharsets = @[@"UTF-8", @"ISO-8859-1", @"US-ASCII"];
}

+ (id) protocolHandlerWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  return [[self alloc] initWithConnectionState: telnetConnectionState];
}

- (id) initWithConnectionState: (MUMUDConnectionState *) telnetConnectionState
{
  if (!(self = [super init]))
    return nil;
  
  subnegotiationBuffer = [[NSMutableData alloc] initWithCapacity: 64];
  
  _state = telnetConnectionState;
  stateMachine = [MUTelnetStateMachine stateMachine];
  receivedCR = NO;
  optionRequestSent = NO;
  
  [self initializeOptions];
  return self;
}

- (void) disableOptionForHim: (uint8_t) option
{
  if (stateMachine.telnetConfirmed)
    [options[option] disableHim];
}

- (void) disableOptionForUs: (uint8_t) option
{
  if (stateMachine.telnetConfirmed)
    [options[option] disableUs];
}

- (void) enableOptionForHim: (uint8_t) option
{
  if (stateMachine.telnetConfirmed)
    [options[option] enableHim];
}

- (void) enableOptionForUs: (uint8_t) option
{
  if (stateMachine.telnetConfirmed)
    [options[option] enableUs];
}

- (BOOL) optionYesForHim: (uint8_t) option
{
  return [options[option] heIsYes];
}

- (BOOL) optionYesForUs: (uint8_t) option
{
  return [options[option] weAreYes];
}

- (void) shouldAllowWill: (BOOL) value forOption: (uint8_t) option
{
  [options[option] heIsAllowedToUse: value];
}

- (void) shouldAllowDo: (BOOL) value forOption: (uint8_t) option
{
  [options[option] weAreAllowedToUse: value];
}

- (BOOL) telnetConfirmed
{
  return stateMachine.telnetConfirmed;
}

#pragma mark - MUTelnetProtocolHandler protocol

- (void) bufferSubnegotiationByte: (uint8_t) byte
{
  [subnegotiationBuffer appendBytes: &byte length: 1];
}

- (void) bufferTextByte: (uint8_t) byte
{
  if (receivedCR && byte != '\r')
  {
    receivedCR = NO;
    if (byte == '\0')
      PASS_ON_PARSED_BYTE ('\r');
    else
      PASS_ON_PARSED_BYTE (byte);
  } 
  else if (byte == '\r')
    receivedCR = YES;
  else
    PASS_ON_PARSED_BYTE (byte);
}

- (void) handleBufferedSubnegotiation
{
  if (subnegotiationBuffer.length == 0)
  {
    [self log: @"  Telnet: Received zero-length subnegotiation."];
  }
  
  const uint8_t *bytes = subnegotiationBuffer.bytes;
  
  switch (bytes[0])
  {
    case MUTelnetOptionTerminalType:
      [self handleTerminalTypeSubnegotiation: subnegotiationBuffer];
      break;
      
    case MUTelnetOptionCharset:
      [self handleCharsetSubnegotiation: subnegotiationBuffer];
      break;
      
    case MUTelnetOptionMSSP:
      [self handleMSSPSubnegotiation: subnegotiationBuffer];
      break;
      
    case MUTelnetOptionMCCP1:
      [self handleMCCPSubnegotiation: subnegotiationBuffer version: MUTelnetOptionMCCP1];
      break;
      
    case MUTelnetOptionMCCP2:
      [self handleMCCPSubnegotiation: subnegotiationBuffer version: MUTelnetOptionMCCP2];
      break;
      
    default:
      [self log: @"Unknown subnegotation for option %@. [%@]",
       [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationBuffer];
      break;
  }
  
  subnegotiationBuffer.data = [NSData data];
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
  [options[option] receivedDo];
  
  if (option == MUTelnetOptionNegotiateAboutWindowSize)
  {
    _state.shouldReportWindowSizeChanges = YES;
    [self.delegate reportWindowSizeToServer];
  }
  else if (option == MUTelnetOptionCharset)
    [self sendCharsetRequestSubnegotiation];
  
  [_state.codebaseAnalyzer noteTelnetDo: option];
}

- (void) receivedDont: (uint8_t) option
{
  [options[option] receivedDont];
  
  if (option == MUTelnetOptionNegotiateAboutWindowSize)
    _state.shouldReportWindowSizeChanges = NO;
  
  [_state.codebaseAnalyzer noteTelnetDont: option];
}

- (void) receivedWill: (uint8_t) option
{
  [options[option] receivedWill];
  
  if (option == MUTelnetOptionEcho)
    _state.serverWillEcho = YES;
  else if (option == MUTelnetOptionMCCP2)
    [self forOption: MUTelnetOptionMCCP1 allowWill: NO allowDo: NO];
  
  [_state.codebaseAnalyzer noteTelnetWill: option];
}

- (void) receivedWont: (uint8_t) option
{
  [options[option] receivedWont];
  
  if (option == MUTelnetOptionEcho)
    _state.serverWillEcho = NO;
  
  [_state.codebaseAnalyzer noteTelnetWont: option];
}

- (void) sendNAWSSubnegotiationWithNumberOfLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns
{
  if (!_state.shouldReportWindowSizeChanges)
    return;
  
  uint8_t nawsSubnegotiationHeader[1] = {MUTelnetOptionNegotiateAboutWindowSize};
  
  NSMutableData *constructedData = [NSMutableData dataWithBytes: nawsSubnegotiationHeader length: 1];
  
  uint8_t width1 = numberOfColumns / 255;
  uint8_t width0 = numberOfColumns % 255;
  uint8_t height1 = numberOfLines / 255;
  uint8_t height0 = numberOfLines % 255;
  
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
  
  [self sendSubnegotiationWithData: constructedData];
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
  [stateMachine parse: byte forProtocolHandler: self];
  
  if (!optionRequestSent && stateMachine.telnetConfirmed)
  {
    optionRequestSent = YES;
    [self negotiateOptions];
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
  
  if ([self optionYesForUs: MUTelnetOptionEndOfRecord])
  {
    uint8_t endOfRecordBytes[] = {MUTelnetInterpretAsCommand, MUTelnetEndOfRecord};
    [footerData appendBytes: &endOfRecordBytes length: 2];
  }
  
  if (stateMachine.telnetConfirmed
      && ![self optionYesForUs: MUTelnetOptionSuppressGoAhead]
      && _state.codebaseAnalyzer.codebaseFamily != MUCodebaseFamilyPennMUSH) // PennMUSH chokes on IAC GA.
  {
    uint8_t goAheadBytes[] = {MUTelnetInterpretAsCommand, MUTelnetGoAhead};
    [footerData appendBytes: &goAheadBytes length: 2];
  } 
  
  PASS_ON_PREPROCESSED_FOOTER_DATA (footerData);
}

#pragma mark - MUTelnetOptionDelegate protocol

- (void) do: (uint8_t) option
{
  [self log: @"    Sent: IAC DO %@.", [MUTelnetOption optionNameForByte: option]];
  [self sendCommand: MUTelnetDo withByte: option];
}

- (void) dont: (uint8_t) option
{
  [self log: @"    Sent: IAC DONT %@.", [MUTelnetOption optionNameForByte: option]];
  [self sendCommand: MUTelnetDont withByte: option];
}

- (void) will: (uint8_t) option
{
  [self log: @"    Sent: IAC WILL %@.", [MUTelnetOption optionNameForByte: option]];
  [self sendCommand: MUTelnetWill withByte: option];
}

- (void) wont: (uint8_t) option
{
  [self log: @"    Sent: IAC WONT %@.", [MUTelnetOption optionNameForByte: option]];
  [self sendCommand: MUTelnetWont withByte: option];
}

#pragma mark - Private methods

- (void) forOption: (uint8_t) option allowWill: (BOOL) willValue allowDo: (BOOL) doValue
{
  [self shouldAllowWill: willValue forOption: option];
  [self shouldAllowDo: doValue forOption: option];
}

- (void) initializeOptions
{
  for (uint8_t i = 0; i < TELNET_OPTION_MAX; i++)
    options[i] = [[MUTelnetOption alloc] initWithOption: i delegate: self];
  
  [self forOption: MUTelnetOptionEcho allowWill: YES allowDo: NO];
  [self forOption: MUTelnetOptionTransmitBinary allowWill: YES allowDo: YES];
  [self forOption: MUTelnetOptionSuppressGoAhead allowWill: YES allowDo: YES];
  [self forOption: MUTelnetOptionTerminalType allowWill: NO allowDo: YES];
  [self forOption: MUTelnetOptionEndOfRecord allowWill: YES allowDo: YES];
  [self forOption: MUTelnetOptionNegotiateAboutWindowSize allowWill: NO allowDo: YES];
  [self forOption: MUTelnetOptionCharset allowWill: YES allowDo: YES];
  [self forOption: MUTelnetOptionMSSP allowWill: YES allowDo: NO];
  [self forOption: MUTelnetOptionMCCP1 allowWill: YES allowDo: NO];
  [self forOption: MUTelnetOptionMCCP2 allowWill: YES allowDo: NO];
}

- (void) negotiateOptions
{
  //[self enableOptionForUs: MUTelnetOptionSuppressGoAhead];
  
  // PennMUSH does not respond well to IAC GA, but it ignores
  // IAC WILL SGA.  If we send IAC DO SGA it will request that
  // we also IAC DO SGA, so that results in a good set of options.
  //[self enableOptionForHim: MUTelnetOptionSuppressGoAhead];
}

- (void) sendCommand: (uint8_t) command withByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (command);
  PASS_ON_PREPROCESSED_BYTE (byte);
  [self sendPreprocessedData];
}

- (void) sendEscapedByte: (uint8_t) byte
{
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (byte);
  [self sendPreprocessedData];
}

@end

#pragma mark -

@implementation MUTelnetProtocolHandler (Subnegotiation)

- (void) sendSubnegotiationWithBytes: (const uint8_t *) payloadBytes length: (NSUInteger) payloadLength
{
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (MUTelnetBeginSubnegotiation);
  
  for (NSUInteger i = 0; i < payloadLength; i++)
    PASS_ON_PREPROCESSED_BYTE (payloadBytes[i]);
  
  PASS_ON_PREPROCESSED_BYTE (MUTelnetInterpretAsCommand);
  PASS_ON_PREPROCESSED_BYTE (MUTelnetEndSubnegotiation);
  
  [self sendPreprocessedData];
}

- (void) sendSubnegotiationWithData: (NSData *) payloadData
{
  [self sendSubnegotiationWithBytes: payloadData.bytes length: payloadData.length];
}

#pragma mark - CHARSET

- (void) handleCharsetSubnegotiation: (NSData *) subnegotiationData
{
  const uint8_t *bytes = [subnegotiationData bytes];
  NSUInteger length = [subnegotiationData length];
  
  if (![self optionYesForHim: MUTelnetOptionCharset])
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
        if ([acceptableCharsets containsObject: charset])
        {
          _state.stringEncoding = [self stringEncodingForName: charset];
          [self sendCharsetAcceptedSubnegotiationForCharset: charset];
          
          if (_state.stringEncoding == NSASCIIStringEncoding)
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
      
      [self sendCharsetRejectedSubnegotiation];
      return;
    }
      
    case MUTelnetCharsetAccepted:
    {
      if (_state.charsetNegotiationStatus != MUTelnetCharsetNegotiationActive)
      {
        [self log: @"  Telnet: Received %@ ACCEPTED subnegotiation, but no active negotiation in progress.", [MUTelnetOption optionNameForByte: bytes[0]]];
      }
      
      if (length == 2)
      {
        [self log: @"  Telnet: Invalid length of %u for %@ ACCEPTED subnegotiation. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
        return;
      }
      
      NSString *acceptedCharset = [[NSString alloc] initWithBytes: bytes + 2 length: length - 2 encoding: NSASCIIStringEncoding];
      
      _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
      
      if ([acceptableCharsets containsObject: acceptedCharset])
      {
        _state.stringEncoding = [self stringEncodingForName: acceptedCharset];
        
        if (_state.stringEncoding == NSASCIIStringEncoding)
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
      if (_state.charsetNegotiationStatus == MUTelnetCharsetNegotiationInactive)
        [self log: @"  Telnet: Received %@ REJECTED subnegotiation, but no active negotiation in progress.", length, [MUTelnetOption optionNameForByte: bytes[0]]];
      
      _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
      
      if (length > 2)
        [self log: @"  Telnet: Invalid length of %u for %@ REJECTED subnegotiation. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      else
        [self log: @"Received: IAC SB %@ REJECTED IAC SE.", [MUTelnetOption optionNameForByte: bytes[0]]];
      return;
      
    case MUTelnetCharsetTTableIs:
      [self log: @"  Telnet: Received %@ TTABLE-IS subnegotiation without offering to accept a translation table. [%@]", length, [MUTelnetOption optionNameForByte: bytes[0]], subnegotiationData];
      [self sendCharsetTTableRejectedSubnegotiation];
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

- (void) sendCharsetAcceptedSubnegotiationForCharset: (NSString *) charset
{
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetAccepted};
  NSMutableData *charsetAcceptedData = [NSMutableData dataWithBytes: bytes length: 2];
  
  [charsetAcceptedData appendBytes: [charset cStringUsingEncoding: NSASCIIStringEncoding]
                            length: [charset lengthOfBytesUsingEncoding: NSASCIIStringEncoding]];
  
  if (_state.charsetNegotiationStatus == MUTelnetCharsetNegotiationActive)
    _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationIgnoreRejected;
  else
    _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  
  [self sendSubnegotiationWithData: charsetAcceptedData];
  [self log: @"    Sent: IAC SB %@ ACCEPTED %@ IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset], charset];
}

- (void) sendCharsetRejectedSubnegotiation
{
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetRejected};
  NSMutableData *charsetRejectedData = [NSMutableData dataWithBytes: bytes length: 2];
  
  if (_state.charsetNegotiationStatus == MUTelnetCharsetNegotiationActive)
    _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationIgnoreRejected;
  else
    _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationInactive;
  
  [self sendSubnegotiationWithData: charsetRejectedData];
  [self log: @"    Sent: IAC SB %@ REJECTED IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset]];
}

- (void) sendCharsetRequestSubnegotiation
{
  if (_state.charsetNegotiationStatus == MUTelnetCharsetNegotiationActive)
    return;
  
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetRequest};
  NSMutableData *charsetRequestData = [NSMutableData dataWithBytes: bytes length: 2];
  
  for (NSString *charset in offerableCharsets)
  {
    uint8_t separator = ';';
    [charsetRequestData appendBytes: &separator length: 1];
    [charsetRequestData appendBytes: [charset cStringUsingEncoding: NSASCIIStringEncoding]
                             length: [charset lengthOfBytesUsingEncoding: NSASCIIStringEncoding]];
  }
  
  _state.charsetNegotiationStatus = MUTelnetCharsetNegotiationActive;
  
  [self sendSubnegotiationWithData: charsetRequestData];
  [self log: @"    Sent: IAC SB %@ REQUEST <%@> IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset], [offerableCharsets componentsJoinedByString: @" "]];
}

- (void) sendCharsetTTableRejectedSubnegotiation
{
  uint8_t bytes[] = {MUTelnetOptionCharset, MUTelnetCharsetTTableRejected};
  NSMutableData *charsetRejectedData = [NSMutableData dataWithBytes: bytes length: 2];
  
  [self sendSubnegotiationWithData: charsetRejectedData];
  [self log: @"    Sent: IAC SB %@ TTABLE-REJECTED IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionCharset]];
}

- (NSStringEncoding) stringEncodingForName: (NSString *) encodingName
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

#pragma mark - MCCP

- (void) handleMCCPSubnegotiation: (NSData *) subnegotiationData version: (uint8_t) versionByte
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
  
  _state.isIncomingStreamCompressed = YES;
}

#pragma mark - MSSP

- (void) handleMSSPSubnegotiation: (NSData *) subnegotiationData
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
        [self logMSSPVariableData: variableData valueData: valueData];
        [variableData setData: [NSMutableData data]];
        [valueData setData: [NSMutableData data]];
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
  
  [self logMSSPVariableData: variableData valueData: valueData];
}

- (void) logMSSPVariableData: (NSData *) variableData valueData: (NSData *) valueData
{
  NSString *variableString = [[NSString alloc] initWithData: variableData encoding: NSASCIIStringEncoding];
  NSString *valueString = [[NSString alloc] initWithData: valueData encoding: NSASCIIStringEncoding];
  
  [_state.codebaseAnalyzer noteMSSPVariable: variableString value: valueString];
  [self log: @"    MSSP:   %@ = %@.", variableString, valueString];
}

#pragma mark - TERMINAL-TYPE

- (void) handleTerminalTypeSubnegotiation: (NSData *) subnegotiationData
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
  [self sendTerminalTypeSubnegotiation];
}

- (void) sendTerminalTypeSubnegotiation
{
  uint8_t prefixBytes[] = {MUTelnetOptionTerminalType, MUTelnetTerminalTypeIs};
  NSMutableData *terminalTypeData = [NSMutableData dataWithBytes: prefixBytes length: 2];
  
  NSString *terminalType = offerableTerminalTypes[_state.nextTerminalTypeIndex++];
  
  if (_state.nextTerminalTypeIndex >= offerableTerminalTypes.count)
    _state.nextTerminalTypeIndex = 0;
  
  [terminalTypeData appendBytes: [terminalType cStringUsingEncoding: NSASCIIStringEncoding]
                         length: [terminalType lengthOfBytesUsingEncoding: NSASCIIStringEncoding]];
  
  [self sendSubnegotiationWithData: terminalTypeData];
  [self log: @"    Sent: IAC SB %@ IS %@ IAC SE.", [MUTelnetOption optionNameForByte: MUTelnetOptionTerminalType], terminalType];
}

@end
