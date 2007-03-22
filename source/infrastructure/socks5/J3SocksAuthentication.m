//
// J3SocksAuthentication.m
//
// Copyright (c) 2006 3James Software
//

#import "J3SocksAuthentication.h"
#import "J3Buffer.h"
#import "J3ByteSource.h"
#import "J3SocksConstants.h"

@implementation J3SocksAuthentication

- (id) initWithUsername: (NSString *) usernameValue password: (NSString *) passwordValue
{
  if (![super init])
    return nil;
  [self at: &username put: usernameValue];
  [self at: &password put: passwordValue];
  return self;
}

- (void) dealloc
{
  [username release];
  [password release];
  [super dealloc];
}

- (void) appendToBuffer: (id <J3Buffer>)buffer
{
  [buffer append: J3SocksUsernamePasswordVersion];
  [buffer append: [username length]];
  [buffer appendString: username];
  [buffer append: [password length]];
  [buffer appendString: password];
}

- (BOOL) authenticated
{
  return authenticated;
}

- (void) parseReplyFromSource: (id <J3ByteSource>)source
{
  uint8_t reply[2] = {0,0};
  
  [J3ByteSource ensureBytesReadFromSource: source intoBuffer: reply ofLength: 2];
  authenticated = !reply[1];
}

@end
