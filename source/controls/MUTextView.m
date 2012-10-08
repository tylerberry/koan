//
// MUTextView.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUTextView.h"

@implementation MUTextView

@synthesize pasteDelegate;
@dynamic monospaceCharacterSize;

#pragma mark - Properties

- (NSSize) monospaceCharacterSize
{
  NSFont *displayFont = [[self layoutManager] substituteFontForFont: [self font]];
  
  return NSMakeSize ([displayFont maximumAdvancement].width,
                     [[self layoutManager] defaultLineHeightForFont: displayFont]);
}

#pragma mark - Overrides

- (void) drawGrid: (NSRect) rect
{
  NSBezierPath *gridLine = [NSBezierPath bezierPath];
  gridLine.lineWidth = 0.5;
  
  for (CGFloat y = self.textContainerInset.height;
       y <= self.bounds.size.height - self.textContainerInset.height;
       y += self.monospaceCharacterSize.height)
  {
    if (y < rect.origin.y || y > rect.origin.y + rect.size.height)
      continue;
    [gridLine moveToPoint: NSMakePoint (rect.origin.x, y)];
    [gridLine lineToPoint: NSMakePoint (rect.origin.x + rect.size.width, y)];
  }
  
  for (CGFloat x = self.textContainerInset.width + self.textContainer.lineFragmentPadding;
       x <= self.bounds.size.width - self.textContainerInset.width - self.textContainer.lineFragmentPadding;
       x += self.monospaceCharacterSize.width)
  {
    if (x < rect.origin.x || x > rect.origin.x + rect.size.width)
      continue;
    [gridLine moveToPoint: NSMakePoint (x, rect.origin.y)];
    [gridLine lineToPoint: NSMakePoint (x, rect.origin.y + rect.size.height)];
  }
  
  [[[NSColor whiteColor] colorWithAlphaComponent: 0.8] set];
  [gridLine stroke];
}

- (void) drawRect: (NSRect) rect
{
  [super drawRect: rect];

  // [self drawGrid: rect];
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
  if (menuItem.action == @selector (paste:)
      || menuItem.action == @selector (pasteAsPlainText:)
      || menuItem.action == @selector (pasteAsRichText:))
  {
    if ([self.delegate respondsToSelector: @selector (textView:pasteAsPlainText:)])
      return YES;
  }
  
  return [super validateMenuItem: menuItem];
}

- (void) insertText: (id) string
{
  BOOL result = NO;
  
  if ([self.pasteDelegate respondsToSelector: @selector (textView:insertText:)])
    result = [self.pasteDelegate textView: self insertText: string];
  
  if (!result)
    [super insertText: string];
}

- (IBAction) paste: (id) sender
{
  [self pasteAsPlainText: sender];
}

- (IBAction) pasteAsPlainText: (id) sender
{
  BOOL result = NO;
  
  if ([self.pasteDelegate respondsToSelector: @selector (textView:pasteAsPlainText:)])
    result = [self.pasteDelegate textView: self pasteAsPlainText: sender];
  
  if (!result)
    [super pasteAsPlainText: sender];
}

- (IBAction) pasteAsRichText: (id) sender
{
  [self pasteAsPlainText: sender];
}

@end
