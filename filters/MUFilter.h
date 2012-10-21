//
// MUFilter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUFiltering

- (NSAttributedString *) filterCompleteLine: (NSAttributedString *) attributedString;
- (NSAttributedString *) filterPartialLine: (NSAttributedString *) attributedString;

@end

#pragma mark -

@interface MUFilter : NSObject <MUFiltering>

+ (id) filter;

@end
