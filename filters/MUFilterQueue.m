//
// MUFilterQueue.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUFilterQueue.h"

@interface MUFilterQueue ()

@property (strong, nonatomic) NSMutableArray *filters;

@end

#pragma mark -

@implementation MUFilterQueue

@synthesize filters;

+ (id) filterQueue
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  self.filters = [[NSMutableArray alloc] init];
  return self;
}

- (NSAttributedString *) processAttributedString: (NSAttributedString *) string
{
  NSAttributedString *returnString = string;
  
  for (NSObject <MUFiltering> *filter in self.filters)
    returnString = [filter filter: returnString];

  return returnString;
}

- (void) addFilter: (NSObject <MUFiltering> *) filter
{
  [self.filters addObject: filter];
}

- (void) clearFilters
{
  [self.filters removeAllObjects];
}

@end
