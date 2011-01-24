//
// MUSOCKS5Authentication.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUSOCKS5Authentication.h"
#import "MUWriteBuffer.h"
#import "MUByteSource.h"
#import "MUSOCKS5Constants.h"

@implementation MUSOCKS5Authentication

+ (MUSOCKS5Authentication *) socksAuthenticationWithUsername: (NSString *) usernameValue password: (NSString *) passwordValue
{
  return [[[MUSOCKS5Authentication alloc] initWithUsername: usernameValue password: passwordValue] autorelease];
}

- (id) initWithUsername: (NSString *) usernameValue password: (NSString *) passwordValue
{
  if (!(self = [super init]))
    return nil;
  
  username = [usernameValue copy];
  password = [passwordValue copy];
  return self;
}

- (void) dealloc
{
  [username release];
  [password release];
  [super dealloc];
}

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer
{
  [buffer appendByte: MUSOCKS5UsernamePasswordVersion];
  [buffer appendByte: [username length]];
  [buffer appendString: username];
  [buffer appendByte: [password length]];
  [buffer appendString: password];
}

- (BOOL) authenticated
{
  return authenticated;
}

- (void) parseReplyFromSource: (NSObject <MUByteSource> *) source
{
  NSData *reply = [source readExactlyLength: 2];
  if ([reply length] != 2)
    return;
  authenticated = ((uint8_t *) [reply bytes])[1] == 0 ? YES : NO;
}

@end
