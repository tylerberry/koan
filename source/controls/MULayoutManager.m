//
//  MULayoutManager.m
//  Koan
//
//  Created by Tyler Berry on 11/27/12.
//  Copyright (c) 2013 3James Software. All rights reserved.
//

#import "MULayoutManager.h"

@implementation MULayoutManager

- (void) underlineGlyphRange: (NSRange) glyphRange
               underlineType: (NSInteger) underlineType
            lineFragmentRect: (NSRect) lineFragmentRect
      lineFragmentGlyphRange: (NSRange) lineFragmentGlyphRange
             containerOrigin: (NSPoint) containerOrigin
{
  // The default implementation does some magic trickery to only draw the underlines under actual characters and not
  // under leading or trailing whitespace, which is exactly the kind of magic trickery that we want to avoid when
  // underlines are sometimes used deliberately for ANSI art formatting. So we take out all the magic and just call the
  // drawing method.
  
  [self drawUnderlineForGlyphRange: glyphRange
                     underlineType: underlineType
                    baselineOffset: 2.0 // This is a magic number? It doesn't look right with 1.0 or 0.0, and it looks
                                        // identical if it's 100.0. The documentation is not very clear.
                  lineFragmentRect: lineFragmentRect
            lineFragmentGlyphRange: lineFragmentGlyphRange
                   containerOrigin: containerOrigin];
}


@end
