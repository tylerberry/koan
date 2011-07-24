//
// MUTelnetConstants.h
//
// Copyright (c) 2011 3James Software.
//

enum MUTelnetCommands
{
  // This command is defined in RFC 885.
  MUTelnetEndOfRecord = 239,
  
  // These commands are defined in RFC 854.
  MUTelnetEndSubnegotiation = 240,
  MUTelnetNoOperation = 241,
  MUTelnetDataMark = 242,
  MUTelnetBreak = 243,
  MUTelnetInterruptProcess = 244,
  MUTelnetAbortOutput = 245,
  MUTelnetAreYouThere = 246,
  MUTelnetEraseCharacter = 247,
  MUTelnetEraseLine = 248,
  MUTelnetGoAhead = 249,
  MUTelnetBeginSubnegotiation = 250,
  MUTelnetWill = 251,
  MUTelnetWont = 252,
  MUTelnetDo = 253,
  MUTelnetDont = 254,
  MUTelnetInterpretAsCommand = 255
};

enum MUTelnetOptions
{
  // These options are defined by various RFCs.
  MUTelnetOptionTransmitBinary = 0,            // RFC 856.
  MUTelnetOptionEcho = 1,                      // RFC 857.
  MUTelnetOptionSuppressGoAhead = 3,           // RFC 858.
  MUTelnetOptionStatus = 5,                    // RFC 859.
  MUTelnetOptionTimingMark = 6,                // RFC 860.
  MUTelnetOptionTerminalType = 24,             // RFC 1091.
  MUTelnetOptionEndOfRecord = 25,              // RFC 885.
  MUTelnetOptionNegotiateAboutWindowSize = 31, // RFC 1073.
  MUTelnetOptionTerminalSpeed = 32,            // RFC 1079.
  MUTelnetOptionToggleFlowControl = 33,        // RFC 1080.
  MUTelnetOptionLineMode = 34,                 // RFC 1184.
  MUTelnetOptionXDisplayLocation = 35,         // RFC 1096.
  MUTelnetOptionEnvironment = 36,              // RFC 1408.
  MUTelnetOptionNewEnvironment = 39,           // RFC 1572.
  MUTelnetOptionCharset = 42,                  // RFC 2066.
  
  // The START-TLS extension is defined in <http://tools.ietf.org/html/draft-altman-telnet-starttls-02>.
  MUTelnetOptionStartTLS = 46,
  
  // MUD Server Data Protocol.
  // The MSDP extension is defined at <http://tintin.sourceforge.net/msdp/>.
  MUTelnetOptionMSDP = 69,
  
  // MUD Server Status Protocol.
  // The MSSP extension is defined at <http://tintin.sourceforge.net/mssp/>.
  MUTelnetOptionMSSP = 70,
  
  // MUD Client Compression Protocol.
  // The MCCP extension is defined at <http://mccp.smaugmuds.org/>.
  MUTelnetOptionMCCP1 = 85,
  MUTelnetOptionMCCP2 = 86,
  
  // MUD eXtension Protocol and MUD Sound Protocol.
  // The MXP extension is defined at <http://www.zuggsoft.com/zmud/mxp.htm>.
  MUTelnetOptionMSP = 90,
  MUTelnetOptionMXP = 91,
  
  // Zenith MUD Protocol, an out-of-band communication protocol.
  // The ZMP protocol is defined at <http://zmp.sourcemud.org/spec.shtml>.
  MUTelnetOptionZMP = 93,
  
  // Aardwolf informal out-of-band protocol.
  // The Aardwolf protocol is sort of documented at <http://www.qondio.com/telnet-options-client-interaction>.
  MUTelnetOptionAardwolf = 102,
  
  // Achaea Telnet Client Protocol.
  // The ATCP protocol is defined at <http://www.ironrealms.com/rapture/manual/files/FeatATCP-txt.html>.
  // More documentation is available at <http://www.mudstandards.org/ATCP_Specification>.
  MUTelnetOptionATCP = 200,
  
  // Generic MUD Communication Protocol, a.k.a. ATCP2.
  // The GMCP protocol is semi-defined at <http://www.mudstandards.org/forum/viewtopic.php?f=7&t=107>.
  // More documentation is available at <http://www.aardwolf.com/wiki/index.php/Clients/GMCP>.
  MUTelnetOptionGMCP = 201
};

enum MUTelnetMSSPSubnegotiationCommands
{
  // These commands are defined in RFC 1091.
  MUTelnetMSSPVariable = 0,
  MUTelnetMSSPValue = 1
};

enum MUTelnetTerminalTypeSubnegotiationCommands
{
  // These commands are defined in RFC 1091.
  MUTelnetTerminalTypeIs = 0,
  MUTelnetTerminalTypeSend = 1
};

enum MUTelnetCharsetSubnegotiationCommands
{
  // These commands are defined in RFC 2066.
  MUTelnetCharsetRequest = 1,
  MUTelnetCharsetAccepted = 2,
  MUTelnetCharsetRejected = 3,
  MUTelnetCharsetTTableIs = 4,
  MUTelnetCharsetTTableRejected = 5,
  MUTelnetCharsetTTableAck = 6,
  MUTelnetCharsetTTableNak = 7
};
