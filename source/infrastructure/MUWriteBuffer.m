//
// MUWriteBuffer.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUWriteBuffer.h"
#import "MUByteDestination.h"

@implementation MUWriteBufferException

@end

#pragma mark -

@interface MUWriteBuffer ()

- (void) ensureLastBlockIsBinary;
- (void) ensureLastBlockIsString;
- (void) removeDataUpTo: (NSUInteger) position;
- (void) setBlocks: (NSArray *) newBlocks;
- (void) write;

@end

#pragma mark -

@implementation MUWriteBuffer

+ (instancetype) buffer
{
  return [[self alloc] init];
}

- (instancetype) init
{
  if (!(self = [super init]))
    return nil;
  
  blocks = [[NSMutableArray alloc] init];
  lastBlock = nil;
  totalLength = 0;
  
  return self;
}


- (void) setByteDestination: (NSObject <MUByteDestination> *) object
{
  destination = object;
}

#pragma mark - MUWriteBuffer protocol

- (void) appendByte: (uint8_t) byte
{
  [self ensureLastBlockIsBinary];
  uint8_t bytes[1] = {byte};
  [lastBlock appendBytes: bytes length: 1];
  totalLength++;
}

- (void) appendCharacter: (unichar) character
{
  [self appendString: [NSString stringWithCharacters: &character length: 1]];
}

- (void) appendData: (NSData *) data
{
  [self ensureLastBlockIsBinary];
  [lastBlock appendData: data];
  totalLength += [data length];  
}

- (void) appendLine: (NSString *) line
{
  [self appendString: [NSString stringWithFormat: @"%@\n", line]];
}

- (void) appendString: (NSString *) string
{
  if (!string)
    return;
  [self ensureLastBlockIsString];
  [lastBlock appendString: string];
  totalLength += [string length];
}

- (const uint8_t *) bytes
{
  return [[self dataValue] bytes];
}

- (void) clear
{
  [self setBlocks: @[]];
  lastBlock = nil;
  totalLength = 0;
}

- (NSData *) dataValue
{
  NSMutableData *accumulator = [NSMutableData data];
  
  for (NSUInteger i = 0; i < [blocks count]; i++)
  {
    id block = blocks[i];
    
    if ([block isKindOfClass: [NSData class]])
      [accumulator appendData: (NSData *) block];
    else if ([block isKindOfClass: [NSString class]])
      [accumulator appendData: [(NSString *) block dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES]];
  }
  
  return accumulator;
}

- (void) flush
{
  while (![self isEmpty])
    [self write];
}

- (BOOL) isEmpty
{
  return [self length] == 0;
}

- (NSUInteger) length
{
  return totalLength;
}

- (NSString *) stringValue
{
  NSMutableString *accumulator = [NSMutableString string];
  
  for (NSUInteger i = 0; i < [blocks count]; i++)
  {
    id block = blocks[i];
    
    if ([block isKindOfClass: [NSString class]])
      [accumulator appendString: (NSString *) block];
    else if ([block isKindOfClass: [NSData class]])
    {
      NSData *data = (NSData *) block;
      NSUInteger dataLength = [data length];
      unichar promotionArray[dataLength];
      const uint8_t *byteArray = (const uint8_t *) [data bytes];
      
      for (NSUInteger j = 0; j < [data length]; j++)
        promotionArray[j] = byteArray[j];
      
      [accumulator appendString: [NSString stringWithCharacters: promotionArray length: dataLength]];
    }
  }
  
  return accumulator;
}

- (void) writeDataWithPriority: (NSData *) data
{
  [destination write: data];
}

#pragma mark - Private methods

- (void) ensureLastBlockIsBinary
{
  if (!lastBlock || !lastBlockIsBinary)
  {
    lastBlock = [NSMutableData data];
    [blocks addObject: lastBlock];
    lastBlockIsBinary = YES;
  }
}

- (void) ensureLastBlockIsString
{
  if (!lastBlock || lastBlockIsBinary)
  {
    lastBlock = [NSMutableString string];
    [blocks addObject: lastBlock];
    lastBlockIsBinary = NO;
  }  
}

- (void) removeDataUpTo: (NSUInteger) position
{
  while (position > 0 && [blocks count] > 0)
  {
    id lowestBlock = blocks[0];
    
    if (position >= [lowestBlock length])
    {
      position -= [lowestBlock length];
      totalLength -= [lowestBlock length];
      if (lowestBlock == lastBlock)
        lastBlock = nil;
      [blocks removeObjectAtIndex: 0];
    }
    else
    {
      if ([lowestBlock isKindOfClass: [NSMutableData class]])
      {
        [(NSMutableData *) lowestBlock setData:
          [(NSMutableData *) lowestBlock subdataWithRange: NSMakeRange (position, [lowestBlock length] - position)]];
        totalLength -= position;
        position = 0;
      }
      else if ([lowestBlock isKindOfClass: [NSMutableString class]])
      {
        [(NSMutableString *) lowestBlock setString:
          [(NSMutableString *) lowestBlock substringFromIndex: position]];
        totalLength -= position;
        position = 0;
      }
    }
  }
}

- (void) setBlocks: (NSArray *) newBlocks
{
  if (blocks == newBlocks)
    return;
  blocks = [newBlocks mutableCopy];
}

- (void) write
{
  if (!destination)
  {
    @throw [MUWriteBufferException exceptionWithName: @"" 
                                              reason: @"Must provide destination" 
                                            userInfo: nil];
  }
  
  [destination write: [self dataValue]];
  [self clear];
}

@end
