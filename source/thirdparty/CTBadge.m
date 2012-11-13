//
// CTBadge.m
// Version: 2.0 modified
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

#import "CTBadge.h"

const CGFloat CTLargeBadgeSize = 56.; // 46. was Weider's value. -- TB
const CGFloat CTSmallBadgeSize = 23.;
const CGFloat CTLargeLabelSize = 30.; // 24. was Weider's value. -- TB
const CGFloat CTSmallLabelSize = 11.;

@interface CTBadge ()

//gradient used to fill badge mask
- (NSGradient *) badgeGradient;

// Return a badge with height of <size> to fit <length> characters
- (NSImage *) badgeMaskOfSize: (CGFloat) size length: (NSUInteger) length;

// Returns appropriately attributed label string (not autoreleased)
- (NSAttributedString *) labelForString: (NSString *) string size: (NSUInteger) size;

// Returns string for display (replaces large numbers with infinity)
- (NSString *) stringForValue: (NSUInteger) value;									

@end

#pragma mark -

@implementation CTBadge

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  _badgeColor = [NSColor redColor];
  _labelColor = [NSColor whiteColor];
	
  return self;
}

+ (CTBadge *) systemBadge
{
  id newInstance = [[[self class] alloc] init];
  
  return newInstance;
}

+ (CTBadge *) badgeWithColor: (NSColor *) newBadgeColor labelColor: (NSColor *) newLabelColor
{
  CTBadge *newInstance = [[[self class] alloc] init];
  
  newInstance.badgeColor = newBadgeColor;
  newInstance.labelColor = newLabelColor;
  
  return newInstance;
}

#pragma mark - Drawing

- (NSImage *) smallBadgeForValue: (NSUInteger) value
{
  return [self badgeOfSize: CTSmallBadgeSize forString: [self stringForValue: value]];
}

- (NSImage *) smallBadgeForString: (NSString *) string
{
  return [self badgeOfSize: CTSmallBadgeSize forString: string];
}

- (NSImage *) largeBadgeForValue: (NSUInteger) value
{
  return [self badgeOfSize: CTLargeBadgeSize forString: [self stringForValue: value]];
}

- (NSImage *) largeBadgeForString: (NSString *) string
{
  return [self badgeOfSize: CTLargeBadgeSize forString: string];
}

- (NSImage *) badgeOfSize: (CGFloat) size forValue: (NSUInteger) value
{
  return [self badgeOfSize: size forString: [self stringForValue: value]];
}

- (NSImage *) badgeOfSize: (CGFloat) size forString: (NSString *) string
{
  CGFloat scaleFactor = 1.;
  
  if (size <= 0)
    [NSException raise: NSInvalidArgumentException
                format: @"%@ %@: size (%f) must be positive", self.class, NSStringFromSelector (_cmd), size];
  else if (size <= CTSmallBadgeSize)
    scaleFactor = size / CTSmallBadgeSize;
  else
    scaleFactor = size / CTLargeBadgeSize;
  
  // Label stuff
  
  NSAttributedString *label;
  NSSize labelSize;
  
  if (size <= CTSmallBadgeSize)
    label = [self labelForString: string size: CTSmallLabelSize * scaleFactor];
  else
    label = [self labelForString: string size: CTLargeLabelSize * scaleFactor];
  
  labelSize = label.size;
  
  // Badge stuff
  
  NSImage *badgeImage;	// this the image with the gradient fill
  NSImage *badgeMask; 	// we nock out this mask from the gradient
  
  NSGradient *badgeGradient = [self badgeGradient];
  
  CGFloat shadowOpacity, shadowOffset, shadowBlurRadius;
  int angle;
  
  if (size <= CTSmallBadgeSize)
	{
    shadowOpacity = .6;
    shadowOffset = floor (1. * scaleFactor);
    shadowBlurRadius = ceil (1. * scaleFactor);
	}
  else
	{
    shadowOpacity = .8;
    shadowOffset = ceil (1. * scaleFactor);
    shadowBlurRadius = ceil (2. * scaleFactor);
	}
  
  if (label.length <= 3) // Badges have different gradient angles
    angle = -45;
  else
    angle = -30;
  
  badgeMask = [self badgeMaskOfSize: size length: label.length];
  
  NSSize badgeSize = badgeMask.size;
  NSPoint origin = NSMakePoint (shadowBlurRadius, shadowBlurRadius + shadowOffset);
  
  NSSize imageSize = NSMakeSize (badgeSize.width + 2 * shadowBlurRadius,
                                badgeSize.height + 2 * shadowBlurRadius - shadowOffset + (size <= CTSmallBadgeSize));
  
  badgeImage = [[NSImage alloc] initWithSize: imageSize];
  
  [badgeImage lockFocus];
	[badgeGradient drawInRect: NSMakeRect (origin.x, origin.y, floor (badgeSize.width), floor (badgeSize.height))
                      angle: angle];
  [badgeMask drawAtPoint: origin fromRect: NSZeroRect operation: NSCompositeDestinationAtop fraction: 1.0];
	[label drawInRect: NSMakeRect (origin.x + floor ((badgeSize.width - labelSize.width) / 2),
                                 origin.y + floor ((badgeSize.height - labelSize.height) / 2),
                                 badgeSize.width,
                                 labelSize.height)]; // Draw label in center
  [badgeImage unlockFocus];
  
  // Final stuff
  
  NSImage *image = [[NSImage alloc] initWithSize: badgeImage.size];
  
  [image lockFocus];
	[NSGraphicsContext saveGraphicsState];
  
  NSShadow *shadow = [[NSShadow alloc] init];
  
  shadow.shadowOffset =  NSMakeSize (0, -shadowOffset);
  shadow.shadowBlurRadius = shadowBlurRadius;
  shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent: shadowOpacity];
  [shadow set];
  
  [badgeImage drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
	[NSGraphicsContext restoreGraphicsState];
  [image unlockFocus];
    
  return image;
}


- (NSImage *) badgeOverlayImageForString: (NSString *) string insetX: (CGFloat) dx y: (CGFloat) dy;
{
  NSImage *badgeImage = [self largeBadgeForString: string];
  NSImage *overlayImage = [[NSImage alloc] initWithSize: NSMakeSize (128, 128)];
  
  // Draw large icon in the upper right corner of the overlay image
  
  [overlayImage lockFocus];
	NSSize badgeSize = badgeImage.size;
  [badgeImage drawAtPoint: NSMakePoint (128 - dx - badgeSize.width, 128 - dy - badgeSize.height)
                 fromRect: NSZeroRect
                operation: NSCompositeSourceOver
                 fraction: 1.0];
  [overlayImage unlockFocus];
  
  return overlayImage;
}

- (void) badgeApplicationDockIconWithString: (NSString *) string insetX: (CGFloat) dx y: (CGFloat) dy;
{
  NSImage *appIcon = [NSImage imageNamed: @"NSApplicationIcon"];
  NSImage *badgeOverlay = [self badgeOverlayImageForString: string insetX: dx y: dy];
  
  // Put the appIcon underneath the badgeOverlay
  
  [badgeOverlay lockFocus];
  [appIcon drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeDestinationOver fraction: 1.0];
  [badgeOverlay unlockFocus];
  
  [NSApp setApplicationIconImage: badgeOverlay];
}

- (NSImage *) badgeOverlayImageForValue: (NSUInteger) value insetX: (CGFloat) dx y: (CGFloat) dy
{
  return [self badgeOverlayImageForString: [self stringForValue: value] insetX: dx y: dy];
}

- (void) badgeApplicationDockIconWithValue: (NSUInteger) value insetX: (CGFloat) dx y: (CGFloat) dy
{
  [self badgeApplicationDockIconWithString: [self stringForValue: value] insetX: dx y: dy];
}

#pragma mark - Private methods

- (NSGradient *) badgeGradient
{
  NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations: self.badgeColor, 0.0, 
                          self.badgeColor, 1/3., 
                          [self.badgeColor shadowWithLevel:1/3.], 1.0, nil];
  
  return gradient;
}

- (NSImage *) badgeMaskOfSize: (CGFloat) size length: (NSUInteger) length
{
  NSImage *badgeMask;
  
  if (length <=2)
    badgeMask = [NSImage imageNamed: @"CTBadge_1.pdf"];
  else if (length <=3)
    badgeMask = [NSImage imageNamed: @"CTBadge_3.pdf"];
  else if (length <=4)
    badgeMask = [NSImage imageNamed: @"CTBadge_4.pdf"];
  else
    badgeMask = [NSImage imageNamed: @"CTBadge_5.pdf"];
  
  if (size > 0 && size != badgeMask.size.height)
	{
    badgeMask.name = nil;
    badgeMask.scalesWhenResized = YES;
    badgeMask.size = NSMakeSize (badgeMask.size.width * (size / badgeMask.size.height), size);
	}
  
  return badgeMask;
}

- (NSAttributedString *) labelForString: (NSString *) label size: (NSUInteger) size
{
  // Set attributes to use on String
  
  NSFont *labelFont;
  
  if (size <= CTSmallLabelSize)
    labelFont = [NSFont boldSystemFontOfSize:size];
  else
    labelFont = [NSFont fontWithName: @"Helvetica-Bold" size: size];
  
  NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
  pStyle.alignment = NSCenterTextAlignment;
  
  NSDictionary *attributes = @{NSForegroundColorAttributeName: self.labelColor,
                              NSFontAttributeName: labelFont};
  
  // Label stuff
  
  if (label.length >= 6) // Replace with summarized string - ellipses at end and a zero-width space to trick us into
                         // using the 5-wide badge
    
    label = [NSString stringWithFormat: @"%@%@",
             [label substringToIndex: 3], @"\xe2\x80\xa6\xe2\x80\x8b"];
  
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: label attributes: attributes];
  
  return attributedString;
}

- (NSString *) stringForValue: (NSUInteger) value
{
  if (value < 100000)
    return [NSString stringWithFormat: @"%lu", value];
  else // Give infinity
    return @"\xe2\x88\x9e";
}

@end
