//
// MUWriteBufferTests.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "J3TestCase.h"

#import "MUByteDestination.h"

@class MUWriteBuffer;

@interface MUWriteBufferTests : J3TestCase <MUByteDestination>
{
  MUWriteBuffer *buffer;
  NSMutableData *output;
}

@end
