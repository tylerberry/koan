//
// NSColor+ANSI.m
//
// Copyright (c) 2013 3James Software.
//

#import "NSColor+ANSI.h"

// The values for the xterm 256 color cube and grayscale below are taken from <http://fansi.org/256Colors.aspx>.

static uint8_t colorCube[216][3] = {
  { 0, 0, 0 }, { 0, 0, 95 }, { 0, 0, 135 }, { 0, 0, 175 }, { 0, 0, 215 }, { 0, 0, 255 },
  { 0, 95, 0 }, { 0, 95, 95 }, { 0, 95, 135 }, { 0, 95, 175 }, { 0, 95, 215 }, { 0, 95, 255 },
  { 0, 135, 0 }, { 0, 135, 95 }, { 0, 135, 135 }, { 0, 135, 175 }, { 0, 135, 215 }, { 0, 135, 255 },
  { 0, 175, 0 }, { 0, 175, 95 }, { 0, 175, 135 }, { 0, 175, 175 }, { 0, 175, 215 }, { 0, 175, 255 },
  { 0, 215, 0 }, { 0, 215, 95 }, { 0, 215, 135 }, { 0, 215, 175 }, { 0, 215, 215 }, { 0, 215, 255 },
  { 0, 255, 0 }, { 0, 255, 95 }, { 0, 255, 135 }, { 0, 255, 175 }, { 0, 255, 215 }, { 0, 255, 255 },
  
  { 95, 0, 0 }, { 95, 0, 95 }, { 95, 0, 135 }, { 95, 0, 175 }, { 95, 0, 215 }, { 95, 0, 255 },
  { 95, 95, 0 }, { 95, 95, 95 }, { 95, 95, 135 }, { 95, 95, 175 }, { 95, 95, 215 }, { 95, 95, 255 },
  { 95, 135, 0 }, { 95, 135, 95 }, { 95, 135, 135 }, { 95, 135, 175 }, { 95, 135, 215 }, { 95, 135, 255 },
  { 95, 175, 0 }, { 95, 175, 95 }, { 95, 175, 135 }, { 95, 175, 175 }, { 95, 175, 215 }, { 95, 175, 255 },
  { 95, 215, 0 }, { 95, 215, 95 }, { 95, 215, 135 }, { 95, 215, 175 }, { 95, 215, 215 }, { 95, 215, 255 },
  { 95, 255, 0 }, { 95, 255, 95 }, { 95, 255, 135 }, { 95, 255, 175 }, { 95, 255, 215 }, { 95, 255, 255 },
  
  { 135, 0, 0 }, { 135, 0, 95 }, { 135, 0, 135 }, { 135, 0, 175 }, { 135, 0, 215 }, { 135, 0, 255 },
  { 135, 95, 0 }, { 135, 95, 95 }, { 135, 95, 135 }, { 135, 95, 175 }, { 135, 95, 215 }, { 135, 95, 255 },
  { 135, 135, 0 }, { 135, 135, 95 }, { 135, 135, 135 }, { 135, 135, 175 }, { 135, 135, 215 }, { 135, 135, 255 },
  { 135, 175, 0 }, { 135, 175, 95 }, { 135, 175, 135 }, { 135, 175, 175 }, { 135, 175, 215 }, { 135, 175, 255 },
  { 135, 215, 0 }, { 135, 215, 95 }, { 135, 215, 135 }, { 135, 215, 175 }, { 135, 215, 215 }, { 135, 215, 255 },
  { 135, 255, 0 }, { 135, 255, 95 }, { 135, 255, 135 }, { 135, 255, 175 }, { 135, 255, 215 }, { 135, 255, 255 },
  
  { 175, 0, 0 }, { 175, 0, 95 }, { 175, 0, 135 }, { 175, 0, 175 }, { 175, 0, 215 }, { 175, 0, 255 },
  { 175, 95, 0 }, { 175, 95, 95 }, { 175, 95, 135 }, { 175, 95, 175 }, { 175, 95, 215 }, { 175, 95, 255 },
  { 175, 135, 0 }, { 175, 135, 95 }, { 175, 135, 135 }, { 175, 135, 175 }, { 175, 135, 215 }, { 175, 135, 255 },
  { 175, 175, 0 }, { 175, 175, 95 }, { 175, 175, 135 }, { 175, 175, 175 }, { 175, 175, 215 }, { 175, 175, 255 },
  { 175, 215, 0 }, { 175, 215, 95 }, { 175, 215, 135 }, { 175, 215, 175 }, { 175, 215, 215 }, { 175, 215, 255 },
  { 175, 255, 0 }, { 175, 255, 95 }, { 175, 255, 135 }, { 175, 255, 175 }, { 175, 255, 215 }, { 175, 255, 255 },
  
  { 215, 0, 0 }, { 215, 0, 95 }, { 215, 0, 135 }, { 215, 0, 175 }, { 215, 0, 215 }, { 215, 0, 255 },
  { 215, 95, 0 }, { 215, 95, 95 }, { 215, 95, 135 }, { 215, 95, 175 }, { 215, 95, 215 }, { 215, 95, 255 },
  { 215, 135, 0 }, { 215, 135, 95 }, { 215, 135, 135 }, { 215, 135, 175 }, { 215, 135, 215 }, { 215, 135, 255 },
  { 215, 175, 0 }, { 215, 175, 95 }, { 215, 175, 135 }, { 215, 175, 175 }, { 215, 175, 215 }, { 215, 175, 255 },
  { 215, 215, 0 }, { 215, 215, 95 }, { 215, 215, 135 }, { 215, 215, 175 }, { 215, 215, 215 }, { 215, 215, 255 },
  { 215, 255, 0 }, { 215, 255, 95 }, { 215, 255, 135 }, { 215, 255, 175 }, { 215, 255, 215 }, { 215, 255, 255 },
  
  { 255, 0, 0 }, { 255, 0, 95 }, { 255, 0, 135 }, { 255, 0, 175 }, { 255, 0, 215 }, { 255, 0, 255 },
  { 255, 95, 0 }, { 255, 95, 95 }, { 255, 95, 135 }, { 255, 95, 175 }, { 255, 95, 215 }, { 255, 95, 255 },
  { 255, 135, 0 }, { 255, 135, 95 }, { 255, 135, 135 }, { 255, 135, 175 }, { 255, 135, 215 }, { 255, 135, 255 },
  { 255, 175, 0 }, { 255, 175, 95 }, { 255, 175, 135 }, { 255, 175, 175 }, { 255, 175, 215 }, { 255, 175, 255 },
  { 255, 215, 0 }, { 255, 215, 95 }, { 255, 215, 135 }, { 255, 215, 175 }, { 255, 215, 215 }, { 255, 215, 255 },
  { 255, 255, 0 }, { 255, 255, 95 }, { 255, 255, 135 }, { 255, 255, 175 }, { 255, 255, 215 }, { 255, 255, 255 } };

static uint8_t grayscale[24] = {
  0, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108, 118, 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228, 238 };

@implementation NSColor (ANSI)

// These values match Mac OS X 10.8 Terminal.app's default values for ANSI colors. There is no standard definition for
// these colors, every terminal and application uses its own. I used these because they're "Mac standard".
//
// I DON'T LIKE THEM VERY MUCH EITHER.

+ (NSColor *) ANSIBlackColor
{
  static NSColor *blackColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    blackColor = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0];
  });
  
  return blackColor;
}

+ (NSColor *) ANSIRedColor
{
  static NSColor *redColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    redColor = [NSColor colorWithCalibratedRed: (154.0 / 256.0) green: 0.0 blue: 0.0 alpha: 1.0];
  });
  
  return redColor;
}

+ (NSColor *) ANSIGreenColor
{
  static NSColor *greenColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    greenColor = [NSColor colorWithCalibratedRed: 0.0 green: (166.0 / 256.0) blue: 0.0 alpha: 1.0];
  });
  
  return greenColor;
}

+ (NSColor *) ANSIYellowColor
{
  static NSColor *yellowColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    yellowColor = [NSColor colorWithCalibratedRed: (154.0 / 256.0) green: (154.0 / 256.0) blue: 0.0 alpha: 1.0];
  });
  
  return yellowColor;
}

+ (NSColor *) ANSIBlueColor
{
  static NSColor *blueColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    blueColor = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: (179.0 / 256.0) alpha: 1.0];
  });
  
  return blueColor;
}

+ (NSColor *) ANSIMagentaColor
{
  static NSColor *magentaColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    magentaColor = [NSColor colorWithCalibratedRed: (179.0 / 256.0) green: 0.0 blue: (179.0 / 256.0) alpha: 1.0];
  });
  
  return magentaColor;
}

+ (NSColor *) ANSICyanColor
{
  static NSColor *cyanColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    cyanColor = [NSColor colorWithCalibratedRed: 0.0 green: (167.0 / 256.0) blue: (179.0 / 256.0) alpha: 1.0];
  });
  
  return cyanColor;
}

+ (NSColor *) ANSIWhiteColor
{
  static NSColor *whiteColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    whiteColor = [NSColor colorWithCalibratedRed: (192.0 / 256.0)
                                           green: (192.0 / 256.0)
                                            blue: (192.0 / 256.0)
                                           alpha: 1.0];
  });
  
  return whiteColor;
}

+ (NSColor *) ANSIBrightBlackColor
{
  static NSColor *brightBlackColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightBlackColor = [NSColor colorWithCalibratedRed: (103.0 / 256.0)
                                                 green: (103.0 / 256.0)
                                                  blue: (103.0 / 256.0)
                                                 alpha: 1.0];
  });
  
  return brightBlackColor;
}

+ (NSColor *) ANSIBrightRedColor
{
  static NSColor *brightRedColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightRedColor = [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: 0.0 blue: 0.0 alpha: 1.0];
  });
  
  return brightRedColor;
}

+ (NSColor *) ANSIBrightGreenColor
{
  static NSColor *brightGreenColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightGreenColor = [NSColor colorWithCalibratedRed: 0.0 green: (218.0 / 256.0) blue: 0.0 alpha: 1.0];
  });
  
  return brightGreenColor;
}

+ (NSColor *) ANSIBrightYellowColor
{
  static NSColor *brightYellowColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightYellowColor = [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: (230.0 / 256.0) blue: 0.0 alpha: 1.0];
  });
  
  return brightYellowColor;
}

+ (NSColor *) ANSIBrightBlueColor
{
  static NSColor *brightBlueColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightBlueColor = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
  });
  
  return brightBlueColor;
}

+ (NSColor *) ANSIBrightMagentaColor
{
  static NSColor *brightMagentaColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightMagentaColor = [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: 0.0 blue: (230.0 / 256.0) alpha: 1.0];
  });
  
  return brightMagentaColor;
}

+ (NSColor *) ANSIBrightCyanColor
{
  static NSColor *brightCyanColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightCyanColor = [NSColor colorWithCalibratedRed: 0.0 green: (230.0 / 256.0) blue: (230.0 / 256.0) alpha: 1.0];
  });
  
  return brightCyanColor;
}

+ (NSColor *) ANSIBrightWhiteColor
{
  static NSColor *brightWhiteColor;
  static dispatch_once_t predicate;
  
  dispatch_once (&predicate, ^{
    brightWhiteColor = [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: (230.0 / 256.0) blue: (230.0 / 256.0) alpha: 1.0];
  });
  
  return brightWhiteColor;
}

+ (NSColor *) ANSI256ColorCubeColorForCode: (uint8_t) code
{
  if (code < 16 || code > 231)
  {
    @throw [NSException exceptionWithName: @"ArgumentException"
                                   reason: @"code argument was outside of color cube range"
                                 userInfo: @{@"argument" : @(code)}];
    return nil;
  }
  
  uint8_t adjustedCode = code - 16;
  
  return [NSColor colorWithCalibratedRed: (colorCube[adjustedCode][0] / 255.0)
                                   green: (colorCube[adjustedCode][1] / 255.0)
                                    blue: (colorCube[adjustedCode][2] / 255.0)
                                   alpha: 1.0];
}

+ (NSColor *) ANSI256GrayscaleColorForCode: (uint8_t) code
{
  if (code < 232)
  {
    @throw [NSException exceptionWithName: @"ArgumentException"
                                   reason: @"code argument was outside of grayscale range"
                                 userInfo: @{@"argument" : @(code)}];
    return nil;
  }
  
  uint8_t adjustedCode = code - 232;
  
  return [NSColor colorWithCalibratedWhite: (grayscale[adjustedCode] / 255.0)
                                     alpha: 1.0];
}

@end
