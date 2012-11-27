//
//  MULayoutManager.m
//  Koan
//
//  Created by Tyler Berry on 11/27/12.
//  Copyright (c) 2012 3James Software. All rights reserved.
//

#import "MULayoutManager.h"

@implementation MULayoutManager

- (void) underlineGlyphRange: (NSRange) glyphRange
               underlineType: (NSInteger) underlineType
            lineFragmentRect: (NSRect) lineFragmentRect
      lineFragmentGlyphRange: (NSRange) lineFragmentGlyphRange
             containerOrigin: (NSPoint) containerOrigin
{
  [self drawUnderlineForGlyphRange: glyphRange
                     underlineType: underlineType
                    baselineOffset: 2.0 // This is a magic number? It doesn't look right with 1.0 or 0.0, and it looks
                                        // identical if it's 100.0. The documentation is not very clear.
                  lineFragmentRect: lineFragmentRect
            lineFragmentGlyphRange: lineFragmentGlyphRange
                   containerOrigin: containerOrigin];
}


@end
