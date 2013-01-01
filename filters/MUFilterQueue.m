//
// MUFilterQueue.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilterQueue.h"

@interface MUFilterQueue ()
{
  NSMutableArray *_filters;
}

@end

#pragma mark -

@implementation MUFilterQueue

@dynamic filters;

+ (id) filterQueue
{
  return [[self alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _filters = [[NSMutableArray alloc] init];
  return self;
}

#pragma mark - Properties

- (NSArray *) filters
{
  @synchronized (_filters)
  {
    return _filters;
  }
}

#pragma mark - Methods

- (NSAttributedString *) processCompleteLine: (NSAttributedString *) attributedString
{
  NSAttributedString *returnString = attributedString;
  
  @synchronized (_filters)
  {
    for (NSObject <MUFiltering> *filter in self.filters)
      returnString = [filter filterCompleteLine: returnString];
  }
  
  return returnString;
}

- (NSAttributedString *) processPartialLine: (NSAttributedString *) attributedString
{
  NSAttributedString *returnString = attributedString;
  
  @synchronized (_filters)
  {
    for (NSObject <MUFiltering> *filter in self.filters)
      returnString = [filter filterPartialLine: returnString];
  }
  
  return returnString;
}

- (void) addFilter: (NSObject <MUFiltering> *) filter
{
  @synchronized (_filters)
  {
    [_filters addObject: filter];
  }
}

- (void) clearFilters
{
  @synchronized (_filters)
  {
    [_filters removeAllObjects];
  }
}

@end
