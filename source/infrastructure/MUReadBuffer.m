//
// MUReadBuffer.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUReadBuffer.h"

NSString *MUReadBufferDidProvideDataNotification = @"MUReadBufferDidProvideDataNotification";
NSString *MUReadBufferDidProvideStringNotification = @"MUReadBufferDidProvideStringNotification";

@interface MUReadBuffer ()

- (void) postDidProvideDataNotificationWithData: (NSData *) data;
- (void) postDidProvideStringNotificationWithString: (NSString *) string;

@end

#pragma mark -

@implementation MUReadBuffer

+ (id) buffer
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  dataBuffer = [[NSMutableData alloc] init];
  
  return self;
}

#pragma mark - MUReadBuffer protocol

- (void) appendByte: (uint8_t) byte
{
  uint8_t bytes[1] = {byte};
  [dataBuffer appendBytes: bytes length: 1];
}

- (void) appendData: (NSData *) data
{
  [dataBuffer appendData: data];
}

- (void) clear
{
  dataBuffer.data = [NSData data];
}

- (NSData *) dataByConsumingBuffer
{
  NSData *data = [NSData dataWithData: dataBuffer];
  [self clear];
  return data;
}

- (NSData *) dataByConsumingBytesToIndex: (NSUInteger) byteIndex
{
  NSData *subdata = [dataBuffer subdataWithRange: NSMakeRange (0, byteIndex)];
  
  [dataBuffer setData: [dataBuffer subdataWithRange: NSMakeRange (byteIndex, self.length - byteIndex)]];
  
  return subdata;
}

- (NSData *) dataValue
{
  return dataBuffer;
}

- (void) postBufferAsData
{
  if (self.length > 0)
  {
    [self postDidProvideDataNotificationWithData: self.dataValue];
    [self clear];
  }
}

- (BOOL) isEmpty
{
  return self.length == 0;
}

- (NSUInteger) length
{
  return dataBuffer.length;
}

- (NSString *) ASCIIStringByConsumingBuffer
{
  return [self stringByConsumingBufferWithEncoding: NSASCIIStringEncoding];
}

- (NSString *) ASCIIStringValue
{
  return [self stringValueWithEncoding: NSASCIIStringEncoding];
}

- (NSString *) stringByConsumingBufferWithEncoding: (NSStringEncoding) encoding
{
  NSString *string = [[NSString alloc] initWithData: self.dataValue encoding: encoding];
  [self clear];
  return string;
}

- (NSString *) stringValueWithEncoding: (NSStringEncoding) encoding
{
  return [[NSString alloc] initWithData: self.dataValue encoding: encoding];
}

#pragma mark - Private methods

- (void) postDidProvideDataNotificationWithData: (NSData *) data
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUReadBufferDidProvideDataNotification
                                                      object: self
                                                    userInfo: @{@"data": data}];
}

- (void) postDidProvideStringNotificationWithString: (NSString *) string
{
  [[NSNotificationCenter defaultCenter] postNotificationName: MUReadBufferDidProvideStringNotification
                                                      object: self
                                                    userInfo: @{@"string": string}];
}

@end
