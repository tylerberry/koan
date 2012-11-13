//
// CTBadge.h
// Version: 2.0
//
// Copyright (c) 2007 Chad Weider.
//
// License:
//
//   Released into Public Domain 4/10/08.
//
// Modifications by Tyler Berry.
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

extern const CGFloat CTLargeBadgeSize;
extern const CGFloat CTSmallBadgeSize;
extern const CGFloat CTLargeLabelSize;
extern const CGFloat CTSmallLabelSize;

@interface CTBadge : NSObject

@property (strong) NSColor *badgeColor;
@property (strong) NSColor *labelColor;

// Classic white on red badge.
+ (CTBadge *) systemBadge;

// Badge of any color scheme.
+ (CTBadge *) badgeWithColor: (NSColor *) badgeColor labelColor: (NSColor *) labelColor;

// Image to use during drag operations.
- (NSImage *) smallBadgeForValue: (NSUInteger) value;				   
- (NSImage *) smallBadgeForString: (NSString *) string;

// For dock icons, etc.
- (NSImage *) largeBadgeForValue: (NSUInteger) value;
- (NSImage *) largeBadgeForString: (NSString *) string;

// A badge of arbitrary size. <size> is the size in pixels of the badge not counting the shadow effect (image returned
// will be larger than <size>).
- (NSImage *) badgeOfSize: (CGFloat) size forValue: (NSUInteger) value;
- (NSImage *) badgeOfSize: (CGFloat) size forString: (NSString *) string;

// Returns a transparent 128x128 image with Large badge inset dx/dy from the upper right.
- (NSImage *) badgeOverlayImageForValue: (NSUInteger) value insetX: (CGFloat) dx y: (CGFloat) dy;
- (NSImage *) badgeOverlayImageForString: (NSString *) string insetX: (CGFloat) dx y: (CGFloat) dy;

// Badges the Application's icon with <value> and puts it on the dock.
- (void) badgeApplicationDockIconWithValue: (NSUInteger) value insetX: (CGFloat) dx y: (CGFloat) dy;
- (void) badgeApplicationDockIconWithString: (NSString *) string insetX: (CGFloat) dx y: (CGFloat) dy;

- (void) setBadgeColor: (NSColor *) theColor;
- (void) setLabelColor: (NSColor *) theColor;

- (NSColor *) badgeColor;
- (NSColor *) labelColor;

@end
