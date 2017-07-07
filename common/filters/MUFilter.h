//
// MUFilter.h
//
// Copyright (c) 2013 3James Software.
//

@protocol MUFiltering

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString;
- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString;

@end

#pragma mark -

@interface MUFilter : NSObject <MUFiltering>

+ (instancetype) filter;

@end
