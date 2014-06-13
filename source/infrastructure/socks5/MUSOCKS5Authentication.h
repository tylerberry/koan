//
// MUSOCKS5Authentication.h
//
// Copyright (c) 2013 3James Software.
//

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5Authentication : NSObject

@property (readonly) BOOL authenticated;

+ (instancetype) socksAuthenticationWithUsername: (NSString *) username
                                        password: (NSString *) password;

- (instancetype) initWithUsername: (NSString *) username
                         password: (NSString *) password;

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (void) parseReplyFromSource: (NSObject <MUByteSource> *) source;

@end
