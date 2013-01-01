//
// MUSOCKS5Authentication.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUSOCKS5Authentication.h"
#import "MUWriteBuffer.h"
#import "MUByteSource.h"
#import "MUSOCKS5Constants.h"

@implementation MUSOCKS5Authentication
{
  NSString *_username;
  NSString *_password;
}

+ (MUSOCKS5Authentication *) socksAuthenticationWithUsername: (NSString *) username
                                                    password: (NSString *) password
{
  return [[MUSOCKS5Authentication alloc] initWithUsername: username password: password];
}

- (id) initWithUsername: (NSString *) username
               password: (NSString *) password
{
  if (!(self = [super init]))
    return nil;
  
  _username = [username copy];
  _password = [password copy];
  _authenticated = NO;
  
  return self;
}

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer
{
  [buffer appendByte: MUSOCKS5UsernamePasswordVersion];
  [buffer appendByte: _username.length];
  [buffer appendString: _username];
  [buffer appendByte: _password.length];
  [buffer appendString: _password];
}

- (void) parseReplyFromSource: (NSObject <MUByteSource> *) source
{
  NSData *reply = [source readExactlyLength: 2];
  
  if (reply.length != 2)
    return;
  
  _authenticated = ((uint8_t *) reply.bytes)[1] == 0 ? YES : NO;
}

@end
