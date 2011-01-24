//
// MUSOCKS5Request.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUSOCKS5Request.h"
#import "MUWriteBuffer.h"
#import "MUByteSource.h"

@implementation MUSOCKS5Request

@synthesize hostname, port;

+ (id) socksRequestWithHostname: (NSString *) hostnameValue port: (int) portValue
{
  return [[[MUSOCKS5Request alloc] initWithHostname: hostnameValue port: portValue] autorelease];
}

- (id) initWithHostname: (NSString *) hostnameValue port: (int) portValue
{
  if (!(self = [super init]))
    return nil;
  hostname = [hostnameValue copy];
  port = portValue;
  reply = MUSOCKS5NoReply;
  return self;
}

- (void) dealloc
{
  [hostname release];
  [super dealloc];
}

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer
{
  [buffer appendByte: MUSOCKS5Version];
  [buffer appendByte: MUSOCKS5Connect];
  [buffer appendByte: 0]; //reserved
  [buffer appendByte: MUSOCKS5DomainName];
  [buffer appendByte: [self.hostname length]];
  [buffer appendString: self.hostname];
  [buffer appendByte: (0xFF00 & self.port) >> 8]; // Most significant byte of port.
  [buffer appendByte: (0x00FF & self.port)];      // Least significant byte of port.
}

- (void) parseReplyFromByteSource: (NSObject <MUByteSource> *) source
{
  NSData *data = [source readExactlyLength: 4];
  if ([data length] != 4)
    return;
  
  const uint8_t *buffer = (const uint8_t *) [data bytes];
  switch (buffer[3])
  {
    case MUSOCKS5IPv4:
      [source readExactlyLength: 4];
      break;
      
    case MUSOCKS5DomainName:
    {
      NSData *lengthData = [source readExactlyLength: 1];
      [source readExactlyLength: ((uint8_t *) [lengthData bytes])[0]];
      break;
    }
      
    case MUSOCKS5IPv6:
      [source readExactlyLength: 16];
      break;
  }
  [source readExactlyLength: 2];
  reply = buffer[1];
}

- (MUSOCKS5Reply) reply
{
  return reply;
}

@end
