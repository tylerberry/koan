//
// MUFormatter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUFormatter

@property (strong, nonatomic, readonly) NSColor *backgroundColor;
@property (strong, nonatomic, readonly) NSFont *font;
@property (strong, nonatomic, readonly) NSColor *foregroundColor;

@end

#pragma mark -

@interface MUFormatter : NSObject <MUFormatter>

+ (id) formatterForTesting;
+ (id) formatterWithForegroundColor: (NSColor *) foregroundColor
                    backgroundColor: (NSColor *) backgroundColor
                               font: (NSFont *) font;

+ (NSColor *) testingBackground;
+ (NSFont *) testingFont;
+ (NSColor *) testingForeground;

- (id) initWithForegroundColor: (NSColor *) foregroundColor
               backgroundColor: (NSColor *) backgroundColor
                          font: (NSFont *) font;

@end
