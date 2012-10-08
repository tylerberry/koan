//
// MUFilter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUFiltering

- (NSAttributedString *) filter: (NSAttributedString *) attributedString;

@end

#pragma mark -

@interface MUFilter : NSObject <MUFiltering>

+ (id) filter;

@end
