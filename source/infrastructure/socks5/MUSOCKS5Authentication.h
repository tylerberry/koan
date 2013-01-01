//
// MUSOCKS5Authentication.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5Authentication : NSObject

+ (MUSOCKS5Authentication *) socksAuthenticationWithUsername: (NSString *) usernameValue
                                                    password: (NSString *) passwordValue;

@property (readonly) BOOL authenticated;

- (id) initWithUsername: (NSString *) usernameValue
               password: (NSString *) passwordValue;

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (void) parseReplyFromSource: (NSObject <MUByteSource> *) source;

@end
