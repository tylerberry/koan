//
// J3FilterQueue.h
//
// Copyright (c) 2010 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "J3Filter.h"

@interface J3FilterQueue : NSObject
{
  NSMutableArray *filters;
}

+ (id) filterQueue;

- (NSAttributedString *) processAttributedString: (NSAttributedString *) string;
- (void) addFilter: (NSObject <J3Filtering> *) filter;
- (void) clearFilters;

@end
