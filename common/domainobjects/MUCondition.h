//
// MUCondition.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

@interface MUCondition : NSObject

@property (copy) NSString *name;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithName: (NSString *) name NS_DESIGNATED_INITIALIZER;

- (void) applyToMutableAttributedString: (NSMutableAttributedString *) mutableAttributedString;

@end
