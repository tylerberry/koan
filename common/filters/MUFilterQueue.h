//
// MUFilterQueue.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUFilter.h"

@interface MUFilterQueue : NSObject

@property (readonly, atomic) NSArray *filters;

+ (instancetype) filterQueue;

- (NSAttributedString *) processCompleteLine: (NSAttributedString *) attributedString;
- (NSAttributedString *) processPartialLine: (NSAttributedString *) attributedString;

- (void) addFilter: (NSObject <MUFiltering> *) filter;
- (void) clearFilters;

@end
