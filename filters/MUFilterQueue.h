//
// MUFilterQueue.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUFilter.h"

@interface MUFilterQueue : NSObject

@property (readonly, atomic) NSArray *filters;

+ (id) filterQueue;

- (NSAttributedString *) processCompleteLine: (NSAttributedString *) attributedString;
- (NSAttributedString *) processPartialLine: (NSAttributedString *) attributedString;

- (void) addFilter: (NSObject <MUFiltering> *) filter;
- (void) clearFilters;

@end
