//
// NSColor+ANSI.h
//
// Copyright (c) 2013 3James Software.
//

@interface NSColor (ANSI)

+ (NSColor *) ANSIBlackColor;
+ (NSColor *) ANSIRedColor;
+ (NSColor *) ANSIGreenColor;
+ (NSColor *) ANSIYellowColor;
+ (NSColor *) ANSIBlueColor;
+ (NSColor *) ANSIMagentaColor;
+ (NSColor *) ANSICyanColor;
+ (NSColor *) ANSIWhiteColor;

+ (NSColor *) ANSIBrightBlackColor;
+ (NSColor *) ANSIBrightRedColor;
+ (NSColor *) ANSIBrightGreenColor;
+ (NSColor *) ANSIBrightYellowColor;
+ (NSColor *) ANSIBrightBlueColor;
+ (NSColor *) ANSIBrightMagentaColor;
+ (NSColor *) ANSIBrightCyanColor;
+ (NSColor *) ANSIBrightWhiteColor;

+ (NSColor *) ANSI256ColorCubeColorForCode: (uint8_t) code;
+ (NSColor *) ANSI256GrayscaleColorForCode: (uint8_t) code;

@end
