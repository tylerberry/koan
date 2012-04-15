//
// MUFilterQueue.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFilterQueue.h"

@implementation MUFilterQueue

+ (id) filterQueue
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  filters = [[NSMutableArray alloc] init];
  return self;
}


- (NSAttributedString *) processAttributedString: (NSAttributedString *) string
{
  NSAttributedString *returnString = string;
  
  for (NSObject <MUFiltering> *filter in filters)
    returnString = [filter filter: returnString];

  return returnString;
}

- (void) addFilter: (NSObject <MUFiltering> *) filter
{
  [filters addObject: filter];
}

- (void) clearFilters
{
  [filters removeAllObjects];
}

@end
