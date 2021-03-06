//
// NSFont+Traits.m
//
// Copyright (c) 2013 3James Software.
//
// License:
// 
//   Permission is hereby granted, free of charge, to any person obtaining a
//   copy of this software and associated documentation files (the "Software"),
//   to deal in the Software without restriction, including without limitation
//   the rights to use, copy, modify, merge, publish, distribute, sublicense,
//   and/or sell copies of the Software, and to permit persons to whom the
//   Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//   DEALINGS IN THE SOFTWARE.
//

#import "NSFont+Traits.h"

@implementation NSFont (Traits)

#pragma mark - Methods

- (NSFont *) boldFontWithRespectTo: (NSFont *) referenceFont
{
  if ([referenceFont hasTrait: NSBoldFontMask])
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSUnboldFontMask];
  else
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSBoldFontMask];
}

- (BOOL) hasTrait: (NSFontTraitMask) trait
{
  return (BOOL) ([[NSFontManager sharedFontManager] traitsOfFont: self] & trait);
}

- (NSFont *) italicFontWithRespectTo: (NSFont *) referenceFont
{
  if ([referenceFont hasTrait: NSItalicFontMask])
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSUnitalicFontMask];
  else
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSItalicFontMask];
}

- (NSFont *) unboldFontWithRespectTo: (NSFont *) referenceFont
{
  if ([referenceFont hasTrait: NSBoldFontMask])
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSBoldFontMask];
  else
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSUnboldFontMask];
}

- (NSFont *) unitalicFontWithRespectTo: (NSFont *) referenceFont
{
  if ([referenceFont hasTrait: NSItalicFontMask])
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSItalicFontMask];
  else
    return [[NSFontManager sharedFontManager] convertFont: self toHaveTrait: NSUnitalicFontMask];
}

@end
