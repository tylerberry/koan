//
// MUFilterQueue.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUFilter.h"

@interface MUFilterQueue : NSObject
{
  NSMutableArray *filters;
}

+ (id) filterQueue;

- (NSAttributedString *) processAttributedString: (NSAttributedString *) string;
- (void) addFilter: (NSObject <MUFiltering> *) filter;
- (void) clearFilters;

@end
