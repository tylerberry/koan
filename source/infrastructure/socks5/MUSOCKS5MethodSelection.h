//
// MUSOCKS5MethodSelection.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUSOCKS5Constants.h"

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5MethodSelection : NSObject

@property (readonly) MUSOCKS5Method selectedMethod;

+ (id) socksMethodSelection;

- (void) addMethod: (MUSOCKS5Method) method;
- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (void) parseResponseFromByteSource: (NSObject <MUByteSource> *) byteSource;

@end
