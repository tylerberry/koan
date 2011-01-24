//
// MUSOCKS5MethodSelection.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUSOCKS5Constants.h"

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5MethodSelection : NSObject
{
  NSMutableData *methods;
  MUSOCKS5Method selectedMethod;
}

+ (id) socksMethodSelection;

- (void) addMethod: (MUSOCKS5Method) method;
- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (MUSOCKS5Method) method;
- (void) parseResponseFromByteSource: (NSObject <MUByteSource> *) byteSource;

@end
