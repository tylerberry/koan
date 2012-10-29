//
// MUOutlineView.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUOutlineView.h"

@implementation MUOutlineView

@dynamic delegate;

- (void) keyDown: (NSEvent *) event
{
  if ([self.delegate respondsToSelector: @selector (outlineView:keyDown:)]
      && [self.delegate outlineView: self keyDown: event])
    return;
    
  [super keyDown: event];
}

@end
