//
// MUPredicateCondition.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

#import "MUCondition.h"

@interface MUPredicateCondition : MUCondition <NSCopying, NSSecureCoding>

@property (copy) NSPredicate *predicate;
@property (copy) NSMutableArray *actions;

// Designated initializer.
- (instancetype) initWithName: (NSString *) name
                    predicate: (NSPredicate *) predicate
                      actions: (NSArray *) actions NS_DESIGNATED_INITIALIZER;

@end
