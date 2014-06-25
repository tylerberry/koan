//
// MUCondition.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

@interface MUCondition : NSObject <NSCopying, NSSecureCoding>

@property (copy) NSPredicate *predicate;
@property (copy) NSMutableArray *actions;

- (instancetype) initWithPredicate: (NSPredicate *) predicate actions: (NSArray *) actions;

- (void) applyToMutableAttributedString: (NSMutableAttributedString *) mutableAttributedString;

@end
