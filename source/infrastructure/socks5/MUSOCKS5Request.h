//
// MUSOCKS5Request.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUSOCKS5Constants.h"

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5Request : NSObject

@property (copy) NSString *hostname;
@property (assign, nonatomic) uint16_t port;
@property (readonly) MUSOCKS5Reply reply;

+ (instancetype) socksRequestWithHostname: (NSString *) hostname port: (uint16_t) port;

- (instancetype) initWithHostname: (NSString *) hostname port: (uint16_t) port;

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (void) parseReplyFromByteSource: (NSObject <MUByteSource> *) source;

@end
