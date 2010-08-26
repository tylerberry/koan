//
// J3SocksRequest.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3SocksRequest.h"
#import "J3WriteBuffer.h"
#import "J3ByteSource.h"

@implementation J3SocksRequest

@synthesize hostname, port;

+ (id) socksRequestWithHostname: (NSString *) hostnameValue port: (int) portValue
{
  return [[[J3SocksRequest alloc] initWithHostname: hostnameValue port: portValue] autorelease];
}

- (id) initWithHostname: (NSString *) hostnameValue port: (int) portValue
{
  if (!(self = [super init]))
    return nil;
  hostname = [hostnameValue copy];
  port = portValue;
  reply = J3SocksNoReply;
  return self;
}

- (void) dealloc
{
  [hostname release];
  [super dealloc];
}

- (void) appendToBuffer: (NSObject <J3WriteBuffer> *) buffer
{
  [buffer appendByte: J3SocksVersion];
  [buffer appendByte: J3SocksConnect];
  [buffer appendByte: 0]; //reserved
  [buffer appendByte: J3SocksDomainName];
  [buffer appendByte: [self.hostname length]];
  [buffer appendString: self.hostname];
  [buffer appendByte: (0xFF00 & self.port) >> 8]; // Most significant byte of port.
  [buffer appendByte: (0x00FF & self.port)];      // Least significant byte of port.
}

- (void) parseReplyFromByteSource: (NSObject <J3ByteSource> *) source
{
  NSData *data = [source readExactlyLength: 4];
  if ([data length] != 4)
    return;
  
  const uint8_t *buffer = (const uint8_t *) [data bytes];
  switch (buffer[3])
  {
    case J3SocksIPV4:
      [source readExactlyLength: 4];
      break;
      
    case J3SocksDomainName:
    {
      NSData *lengthData = [source readExactlyLength: 1];
      [source readExactlyLength: ((uint8_t *) [lengthData bytes])[0]];
      break;
    }
      
    case J3SocksIPV6:
      [source readExactlyLength: 16];
      break;
  }
  [source readExactlyLength: 2];
  reply = buffer[1];
}

- (J3SocksReply) reply
{
  return reply;
}

@end
