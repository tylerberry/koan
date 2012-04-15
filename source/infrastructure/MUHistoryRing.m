//
// MUHistoryRing.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUHistoryRing.h"

@implementation MUHistoryRing

+ (id) historyRing
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;

  ring = [[NSMutableArray alloc] init];
  updates = [[NSMutableDictionary alloc] init];
  cursor = -1;
  searchCursor = -1;
  
  return self;
}


#pragma mark -
#pragma mark Accessors

- (NSUInteger) count
{
  return [ring count];
}

- (NSString *) stringAtIndex: (NSInteger) ringIndex
{
  if (ringIndex == -1)
    return buffer == nil ? @"" : buffer;
  else
  {
    NSString *string = [updates objectForKey: [NSNumber numberWithInteger: ringIndex]];
    
    if (string)
      return string;
    else
      return [ring objectAtIndex: ringIndex];
  }
}

#pragma mark -
#pragma mark Actions

- (void) saveString: (NSString *) string
{
  NSString *copy = [string copy];
  
  [updates removeObjectForKey: [NSNumber numberWithInteger: cursor]];
  
  if (!(cursor != -1 && cursor == (int) ([self count] - 1) && [string isEqualToString: [ring objectAtIndex: cursor]]))
  {
    [ring addObject: copy];
  }
  buffer = nil;
  cursor = -1;
  searchCursor = -1;
}

- (void) updateString: (NSString *) string
{
  NSString *copy = [string copy];
  
  if (cursor == -1)
  {
    buffer = copy;
  }
  else
  {
    [updates setObject: copy forKey: [NSNumber numberWithInteger: cursor]];
  }
}

- (NSString *) currentString
{
  return [self stringAtIndex: cursor];
}

- (NSString *) nextString
{
  cursor++;
  
  if (cursor >= (int) [self count] || cursor < -1)
    cursor = -1;
  
  searchCursor = cursor;
  
  return [self stringAtIndex: cursor];
}

- (NSString *) previousString
{
  cursor--;
  
  if (cursor == -2)
    cursor = [self count] - 1;
  else if (cursor >= (int) [self count] || cursor < -2)
    cursor = -1;
  
  searchCursor = cursor;
  
  return [self stringAtIndex: cursor];
}

- (void) resetSearchCursor
{
  searchCursor = cursor;
}

- (NSUInteger) numberOfUniqueMatchesForStringPrefix: (NSString *) prefix
{
  NSInteger savedCursor = searchCursor;
  NSUInteger uniqueMatchCount = 0;
  NSMutableDictionary *uniqueMatchDictionary = [[NSMutableDictionary alloc] init];
  
  searchCursor = 0;
  
  while (searchCursor < (NSInteger) [self count])
  {
    NSString *candidate = [self stringAtIndex: searchCursor];
    
    if ([candidate hasPrefix: prefix] && ![candidate isEqualToString: prefix])
    {
      if (![uniqueMatchDictionary objectForKey: candidate])
      {
        [uniqueMatchDictionary setObject: [NSNull null] forKey: candidate];
        uniqueMatchCount++;
      }
    }
    
    searchCursor++;
  }
  
  searchCursor = savedCursor;
    
  return uniqueMatchCount;
}

- (NSString *) searchForwardForStringPrefix: (NSString *) prefix
{
  NSInteger originalSearchCursor = searchCursor;
  
  if ([prefix length] == 0)
    return nil;
  
  searchCursor++;
  
  while (searchCursor != originalSearchCursor)
  {
    if (searchCursor > ((NSInteger) [self count] - 1))
    {
      searchCursor = -1;
      if (originalSearchCursor == -1)
        return nil;
    }
    
    if (searchCursor != -1)
    {
      NSString *candidate = [self stringAtIndex: searchCursor];
      
      if ([candidate hasPrefix: prefix] && ![candidate isEqualToString: prefix])
        return candidate;
    }
    
    searchCursor++;
  }
  
  return nil;
}

- (NSString *) searchBackwardForStringPrefix: (NSString *) prefix
{
  NSInteger originalSearchCursor = searchCursor;
  
  if ([prefix length] == 0)
    return nil;
  
  searchCursor--;
  
  while (searchCursor != originalSearchCursor)
  {
    if (searchCursor < 0)
    {
      searchCursor = [self count] - 1;
      if (originalSearchCursor == (int) ([self count] - 1))
        return nil;
    }
    
    if (searchCursor != -1)
    {
      NSString *candidate = [self stringAtIndex: searchCursor];
      
      if ([candidate hasPrefix: prefix] && ![candidate isEqualToString: prefix])
        return candidate;
    }
    
    searchCursor--;
  }
  
  return nil;
}

@end
