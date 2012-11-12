//
// MUProfileContentView.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUProfileContentView.h"

@implementation MUProfileContentView

- (void) awakeFromNib
{
  self.frame = NSMakeRect (self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 1);
  self.autoresizingMask = NSViewWidthSizable;
}

#pragma mark - Methods

- (void) removeAllSubviews
{
  CGFloat frameWidth = self.frame.size.width;
  
  NSView *lastSubview = self.subviews.lastObject;
  
  if (lastSubview)
    self.nextKeyView = lastSubview.nextKeyView;
  
  self.subviews = @[];
  
  self.frame = NSMakeRect (self.frame.origin.x, self.frame.origin.y, frameWidth, 1);
}

#pragma mark - NSView method overrides

- (void) addSubview: (NSView *) view
{
  NSView *lastSubview = self.subviews.lastObject;
  
  if (lastSubview)
  {
    NSRect boxFrame = NSMakeRect (0, lastSubview.frame.origin.y + lastSubview.frame.size.height,
                                  self.frame.size.width, 1);
    NSBox *box = [[NSBox alloc] initWithFrame: boxFrame];
    
    box.boxType = NSBoxCustom;
    box.borderColor = [NSColor windowFrameColor];
    box.autoresizingMask = NSViewWidthSizable;
    
    [super addSubview: box];
    
    view.frame = NSMakeRect (0, lastSubview.frame.origin.y + lastSubview.frame.size.height + 1,
                             self.frame.size.width, view.frame.size.height);
    
    lastSubview.nextKeyView = view;
  }
  else
  {
    view.frame = NSMakeRect (0, 0, self.frame.size.width, view.frame.size.height);
  }
  
  [super addSubview: view];
  
  CGFloat totalHeight = 0.0;
  
  for (NSView *subview in self.subviews)
    totalHeight += subview.frame.size.height;
  
  self.frame = NSMakeRect (self.frame.origin.x, self.frame.origin.y, self.frame.size.width, totalHeight);
  if (totalHeight > self.enclosingScrollView.documentVisibleRect.size.height)
    [self.enclosingScrollView flashScrollers];
}

- (BOOL) isFlipped
{
  return YES;
}

@end
