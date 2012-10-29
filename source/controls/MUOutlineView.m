//
//  MUOutlineView.m
//  Koan
//
//  Created by Tyler Berry on 10/27/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
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
