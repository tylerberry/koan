//
// NSColor (ANSI).m
//
// Copyright (c) 2012 3James Software.
//

#import "NSColor (ANSI).h"

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
  int red = adjustedCode / 36;
  int green = (adjustedCode % 36) / 6;
  int blue = (adjustedCode % 36) % 6;
  
  return [NSColor colorWithCalibratedRed: (1.0 / 6.0 * red)
                                   green: (1.0 / 6.0 * green)
                                    blue: (1.0 / 6.0 * blue)
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
  
  uint8_t adjustedCode = code - 231;
  
  return [NSColor colorWithCalibratedWhite: (1.0 / 25.0 * adjustedCode)
                                     alpha: 1.0];
}

@end
