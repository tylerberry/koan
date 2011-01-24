//
// MUFilter.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUFiltering

- (NSAttributedString *) filter: (NSAttributedString *) string;

@end

#pragma mark -

@interface MUFilter : NSObject <MUFiltering>

+ (id) filter;

@end
