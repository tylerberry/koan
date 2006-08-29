//
// J3SocksRequest.h
//
// Copyright (c) 2006 3James Software
//

#import <Cocoa/Cocoa.h>
#import "J3SocksConstants.h"

@protocol J3Buffer;
@protocol J3ByteSource;

@interface J3SocksRequest : NSObject 
{
  NSString *hostname;
  int port;
  J3SocksReply reply;
}

- (id) initWithHostname:(NSString *)hostnameValue port:(int)portValue;
- (void) appendToBuffer:(id <J3Buffer>)buffer;
- (void) parseReplyFromByteSource:(id <J3ByteSource>)source;
- (J3SocksReply) reply;

@end