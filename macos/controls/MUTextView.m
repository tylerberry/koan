//
// MUTextView.m
//
// Copyright (c) 2013 3James Software.
//

#import "MUTextView.h"

#import "tgmath.h"

@implementation MUTextView

@dynamic monospaceCharacterHeight, monospaceCharacterSize, monospaceCharacterWidth, numberOfColumns, numberOfLines;

#pragma mark - Properties

- (CGFloat) monospaceCharacterHeight
{
  return [self.layoutManager defaultLineHeightForFont: self.font];
}

- (NSSize) monospaceCharacterSize
{
  return NSMakeSize (self.monospaceCharacterWidth, self.monospaceCharacterHeight);
}

- (CGFloat) monospaceCharacterWidth
{
  return self.font.maximumAdvancement.width;
}

- (NSUInteger) numberOfColumns
{
  CGFloat availableHorizontalSpace = self.enclosingScrollView ? self.enclosingScrollView.contentSize.width
                                                              : self.bounds.size.width;
  
  return [self numberOfColumnsForWidth: availableHorizontalSpace];
}

- (NSUInteger) numberOfLines
{
  CGFloat availableVerticalSpace = self.enclosingScrollView ? self.enclosingScrollView.contentSize.height
                                                            : self.bounds.size.height;
  
  return [self numberOfLinesForHeight: availableVerticalSpace];
}

#pragma mark - Methods

- (CGFloat) minimumHeightForLines: (NSUInteger) numberOfLines
{
  CGFloat characterAreaHeight = numberOfLines * self.monospaceCharacterHeight;

  return characterAreaHeight + (2 * self.textContainerInset.height);
}

- (CGFloat) minimumWidthForColumns: (NSUInteger) numberOfColumns
{
  CGFloat characterAreaWidth = numberOfColumns * self.monospaceCharacterWidth;

  return characterAreaWidth + 2 * (self.textContainerInset.width + self.textContainer.lineFragmentPadding);
}

- (NSUInteger) numberOfColumnsForWidth: (CGFloat) width
{
  if (self.monospaceCharacterWidth == 0.0) // Dividing by zero is bad. :)
    return 0;

  width -= 2 * (self.textContainerInset.width + self.textContainer.lineFragmentPadding);
  
  return (NSUInteger) floor (width / self.monospaceCharacterWidth);
}

- (NSUInteger) numberOfLinesForHeight: (CGFloat) height
{
  if (self.monospaceCharacterHeight == 0.0) // Dividing by zero is still bad. :)
    return 0;

  height -= 2 * self.textContainerInset.height;

  return (NSUInteger) floor (height / self.monospaceCharacterHeight);
}

#pragma mark - Overrides

- (void) drawGrid: (NSRect) rect
{
  NSBezierPath *gridLine = [NSBezierPath bezierPath];
  gridLine.lineWidth = 0.5;
  
  CGFloat y = self.textContainerInset.height;

  if (self.monospaceCharacterHeight == 0.0
      || self.monospaceCharacterWidth == 0.0)
    return;

  while (y <= self.bounds.size.height - self.textContainerInset.height)
  {
    if (y < rect.origin.y || y > rect.origin.y + rect.size.height)
    {
      y += self.monospaceCharacterHeight;
      continue;
    }
    [gridLine moveToPoint: NSMakePoint (rect.origin.x, y)];
    [gridLine lineToPoint: NSMakePoint (rect.origin.x + rect.size.width, y)];

    y += self.monospaceCharacterHeight;
  }
  
  for (CGFloat x = self.textContainerInset.width + self.textContainer.lineFragmentPadding;
       x <= self.bounds.size.width - self.textContainerInset.width - self.textContainer.lineFragmentPadding;
       x += self.monospaceCharacterWidth)
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

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
  if (menuItem.action == @selector (paste:)
      || menuItem.action == @selector (pasteAsPlainText:)
      || menuItem.action == @selector (pasteAsRichText:))
  {
    return [self.delegate respondsToSelector: @selector (textView:pasteAsPlainText:)];
  }
  
  return [super validateMenuItem: menuItem];
}

- (void) insertText: (id) string replacementRange: (NSRange) replacementRange
{
  BOOL result = NO;
  
  if ([self.pasteDelegate respondsToSelector: @selector (textView:insertText:)])
    result = [self.pasteDelegate textView: self insertText: string];
  
  if (!result)
    [super insertText: string replacementRange: replacementRange];
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
