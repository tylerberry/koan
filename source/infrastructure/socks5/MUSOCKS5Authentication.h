//
// MUSOCKS5Authentication.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5Authentication : NSObject
{
  NSString *username;
  NSString *password;
  BOOL authenticated;
}

+ (MUSOCKS5Authentication *) socksAuthenticationWithUsername: (NSString *) usernameValue password: (NSString *) passwordValue;

- (id) initWithUsername: (NSString *) usernameValue password: (NSString *) passwordValue;

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (BOOL) authenticated;
- (void) parseReplyFromSource: (NSObject <MUByteSource> *) source;

@end
