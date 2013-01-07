//
// MUSOCKS5Constants.h
//
// Copyright (c) 2013 3James Software.
//

enum MUSOCKS5Miscellaneous
{
  MUSOCKS5Version = 0x05,
  MUSOCKS5UsernamePasswordVersion = 0x01
};

typedef enum MUSOCKS5AddressType
{
  MUSOCKS5IPv4 = 0x01,
  MUSOCKS5DomainName = 0x03,
  MUSOCKS5IPv6 = 0x04
} MUSOCKS5AddressType;

typedef enum MUSOCKS5Method
{
  MUSOCKS5NoAuthentication = 0x00,
  MUSOCKS5GssApi = 0x01,
  MUSOCKS5UsernamePassword = 0x02,
  MUSOCKS5NoAcceptableMethods = 0xFF
} MUSOCKS5Method;

typedef enum MUSOCKS5Command
{
  MUSOCKS5Connect = 0x01,
  MUSOCKS5Bind = 0x02,
  MUSOCKS5UDPAssociate = 0x03
} MUSOCKS5Command;

typedef enum MUSOCKS5Reply
{
  MUSOCKS5NoReply = -1,
  MUSOCKS5Success = 0x00,
  MUSOCKS5GeneralServerFailure = 0x01,
  MUSOCKS5ConnectionNotAllowed = 0x02,
  MUSOCKS5NetworkUnreachable = 0x03,
  MUSOCKS5HostUnreachable = 0x04,
  MUSOCKS5ConnectionRefused = 0x05,
  MUSOCKS5TimeToLiveExpired = 0x06,
  MUSOCKS5CommandNotSupported = 0x07,
  MUSOCKS5AddressTypeNotSupported = 0x08
} MUSOCKS5Reply;
