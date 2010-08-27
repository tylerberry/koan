//
// J3FilterQueue.m
//
// Copyright (c) 2010 3James Software.
//

#import "J3FilterQueue.h"

@implementation J3FilterQueue

+ (id) filterQueue
{
  return [[[self alloc] init] autorelease];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  filters = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  [filters release];
  [super dealloc];
}

- (NSAttributedString *) processAttributedString: (NSAttributedString *) string
{
  NSAttributedString *returnString = string;
  
  for (NSObject <J3Filtering> *filter in filters)
    returnString = [filter filter: returnString];

  return returnString;
}

- (void) addFilter: (NSObject <J3Filtering> *) filter
{
  [filters addObject: filter];
}

- (void) clearFilters
{
  [filters removeAllObjects];
}

@end
