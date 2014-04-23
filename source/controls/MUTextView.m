//
// MUTextView.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextView.h"

@implementation MUTextView

@dynamic monospaceCharacterHeight, monospaceCharacterSize, monospaceCharacterWidth, numberOfColumns, numberOfLines;

#pragma mark - Properties

- (CGFloat) monospaceCharacterHeight
{
  return [self.layoutManager defaultLineHeightForFont: [self.layoutManager substituteFontForFont: self.font]];
}

- (NSSize) monospaceCharacterSize
{
  return NSMakeSize (self.monospaceCharacterWidth, self.monospaceCharacterHeight);
}

- (CGFloat) monospaceCharacterWidth
{
  return [self.layoutManager substituteFontForFont: self.font].maximumAdvancement.width;
}

- (NSUInteger) numberOfColumns
{
  CGFloat availableHorizontalSpace;
  
  if (self.enclosingScrollView)
    availableHorizontalSpace = self.enclosingScrollView.contentSize.width;
  else
    availableHorizontalSpace = self.bounds.size.width;
  
  availableHorizontalSpace -= 2 * (self.textContainerInset.width + self.textContainer.lineFragmentPadding);
  
  return (NSUInteger) (availableHorizontalSpace / self.monospaceCharacterWidth);
}

- (NSUInteger) numberOfLines
{
  CGFloat availableVerticalSpace;
  
  if (self.enclosingScrollView)
    availableVerticalSpace = self.enclosingScrollView.contentSize.height;
  else
    availableVerticalSpace = self.bounds.size.height;
  
  availableVerticalSpace -= 2 * self.textContainerInset.height;
  
  return (NSUInteger) (availableVerticalSpace / self.monospaceCharacterHeight);
}

- (void) scrollRangeToVisible: (NSRange) range animate: (BOOL) animateScrolling
{
  if (animateScrolling)
  {
    NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange: range actualCharacterRange: NULL];
    NSRect glyphRect = [self.layoutManager boundingRectForGlyphRange: glyphRange
                                                     inTextContainer: self.textContainer];
    
    [NSAnimationContext beginGrouping];
    [NSAnimationContext currentContext].duration = 1.0f;
    [self.enclosingScrollView.contentView.animator setBoundsOrigin: glyphRect.origin];
    [NSAnimationContext endGrouping];
  }
  else
    [self scrollRangeToVisible: range];
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

  //[self drawGrid: rect];
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

- (IBAction) performFindPanelAction: (id) sender
{
  BOOL result = NO;
  
  if ([self.pasteDelegate respondsToSelector: @selector (textView:performFindPanelAction:)])
    result = [self.pasteDelegate textView: self performFindPanelAction: sender];
  
  if (!result)
    [super performFindPanelAction: sender];
}

@end
