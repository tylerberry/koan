//
// MUHistoryRing.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUHistoryRing.h"

@interface MUHistoryRing ()

@property (copy, nonatomic) NSString *buffer;
@property (nonatomic) NSUInteger cursor;
@property (strong, nonatomic) NSMutableArray *ring;
@property (nonatomic) NSUInteger searchCursor;
@property (strong, nonatomic) NSMutableDictionary *updates;

@end

#pragma mark -

@implementation MUHistoryRing

@dynamic count;

+ (id) historyRing
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;

  _buffer = nil;
  _cursor = NSNotFound;
  _ring = [[NSMutableArray alloc] init];
  _searchCursor = NSNotFound;
  _updates = [[NSMutableDictionary alloc] init];
  
  return self;
}

#pragma mark - Accessors

- (NSUInteger) count
{
  return self.ring.count;
}

- (NSString *) stringAtIndex: (NSUInteger) ringIndex
{
  if (ringIndex == NSNotFound)
    return self.buffer == nil ? @"" : self.buffer;
  else
  {
    NSString *string = self.updates[@(ringIndex)];
    
    if (string)
      return string;
    else
      return self.ring[ringIndex];
  }
}

#pragma mark - Actions

- (void) saveString: (NSString *) string
{
  NSString *copy = [string copy];
  
  [self.updates removeObjectForKey: @(self.cursor)];
  
  if (!(self.cursor != NSNotFound
        && self.cursor == self.count - 1
        && [string isEqualToString: self.ring[self.cursor]]))
    [self.ring addObject: copy];
  
  self.buffer = nil;
  self.cursor = NSNotFound;
  self.searchCursor = NSNotFound;
}

- (void) updateString: (NSString *) string
{
  NSString *copy = [string copy];
  
  if (self.cursor == NSNotFound)
  {
    self.buffer = copy;
  }
  else
  {
    self.updates[@(self.cursor)] = copy;
  }
}

- (NSString *) currentString
{
  return [self stringAtIndex: self.cursor];
}

- (NSString *) nextString
{
  if (self.cursor == NSNotFound)
    self.cursor = 0;
  else if (self.cursor == self.count - 1)
    self.cursor = NSNotFound;
  else
    self.cursor++;
  
  self.searchCursor = self.cursor;
  
  return [self stringAtIndex: self.cursor];
}

- (NSString *) previousString
{
  if (self.cursor == NSNotFound)
    self.cursor = self.count - 1;
  else if (self.cursor == 0)
    self.cursor = NSNotFound;
  else
    self.cursor--;
  
  self.searchCursor = self.cursor;
  
  return [self stringAtIndex: self.cursor];
}

- (void) resetSearchCursor
{
  self.searchCursor = self.cursor;
}

- (NSUInteger) numberOfUniqueMatchesForStringPrefix: (NSString *) prefix
{
  NSInteger savedCursor = self.searchCursor;
  NSUInteger uniqueMatchCount = 0;
  NSMutableDictionary *uniqueMatchDictionary = [[NSMutableDictionary alloc] init];
  
  self.searchCursor = 0;
  
  while (self.searchCursor < self.count)
  {
    NSString *candidate = [self stringAtIndex: self.searchCursor];
    
    if ([candidate hasPrefix: prefix] && ![candidate isEqualToString: prefix])
    {
      if (!uniqueMatchDictionary[candidate])
      {
        uniqueMatchDictionary[candidate] = [NSNull null];
        uniqueMatchCount++;
      }
    }
    
    self.searchCursor++;
  }
  
  self.searchCursor = savedCursor;
    
  return uniqueMatchCount;
}

- (NSString *) searchForwardForStringPrefix: (NSString *) prefix
{
  NSUInteger originalSearchCursor = self.searchCursor;
  
  if (prefix.length == 0)
    return nil;
  
  do
  {
    if (self.searchCursor == self.count - 1)
    {
      self.searchCursor = NSNotFound;
      if (originalSearchCursor == NSNotFound)
        return nil;
    }
    else if (self.searchCursor == NSNotFound)
      self.searchCursor = 0;
    else
      self.searchCursor++;
    
    if (self.searchCursor != NSNotFound)
    {
      NSString *candidate = [self stringAtIndex: self.searchCursor];
      
      if ([candidate hasPrefix: prefix] && ![candidate isEqualToString: prefix])
        return candidate;
    }
  }
  while (self.searchCursor != originalSearchCursor);
  
  return nil;
}

- (NSString *) searchBackwardForStringPrefix: (NSString *) prefix
{
  NSUInteger originalSearchCursor = self.searchCursor;
  
  if (prefix.length == 0)
    return nil;
  
  do
  {
    if (self.searchCursor == NSNotFound)
    {
      self.searchCursor = self.count - 1;
      if (originalSearchCursor == self.count - 1)
        return nil;
    }
    else if (self.searchCursor == 0)
    {
      self.searchCursor = NSNotFound;
      if (originalSearchCursor == NSNotFound)
        return nil;
    }
    else
      self.searchCursor--;
    
    if (self.searchCursor != NSNotFound)
    {
      NSString *candidate = [self stringAtIndex: self.searchCursor];
      
      if ([candidate hasPrefix: prefix] && ![candidate isEqualToString: prefix])
        return candidate;
    }
  }
  while (self.searchCursor != originalSearchCursor);
  
  return nil;
}

@end
