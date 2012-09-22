//
// MUFilterQueue.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUFilter.h"

@interface MUFilterQueue : NSObject

+ (id) filterQueue;

- (NSAttributedString *) processAttributedString: (NSAttributedString *) string;
- (void) addFilter: (NSObject <MUFiltering> *) filter;
- (void) clearFilters;

@end
