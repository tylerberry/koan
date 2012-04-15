//
// MUFormatter.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

@protocol MUFormatter

- (NSColor *) background;
- (NSFont *) font;
- (NSColor *) foreground;

@end

#pragma mark -

@interface MUFormatter : NSObject <MUFormatter>
{
  NSColor *background;
  NSFont *font;
  NSColor *foreground;
}

+ (id) formatterForTesting;
+ (id) formatterWithForegroundColor: (NSColor *) fore backgroundColor: (NSColor *) back font: (NSFont *) font;
+ (NSColor *) testingBackground;
+ (NSFont *) testingFont;
+ (NSColor *) testingForeground;

- (id) initWithForegroundColor: (NSColor *) fore backgroundColor: (NSColor *) back font: (NSFont *) font;

@end
