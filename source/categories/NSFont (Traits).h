//
// NSFont (Traits).h
//
// Copyright (c) 2007 3James Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFont (Traits)

- (NSFont *) fontWithTrait: (NSFontTraitMask)trait;
- (BOOL) hasTrait: (NSFontTraitMask)trait;
- (BOOL) isBold;
- (BOOL) isItalic;

@end
