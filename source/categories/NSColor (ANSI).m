//
// NSColor (ANSI).m
//
// Copyright (c) 2012 3James Software.
//

#import "NSColor (ANSI).h"

@implementation NSColor (ANSI)

// These values match Mac OS X 10.8 Terminal.app's default values for ANSI colors.
//
// I DON'T LIKE THEM EITHER.

+ (NSColor *) ANSIBlackColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIRedColor
{
  return [NSColor colorWithCalibratedRed: (154.0 / 256.0) green: 0.0 blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIGreenColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: (166.0 / 256.0) blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIYellowColor
{
  return [NSColor colorWithCalibratedRed: (154.0 / 256.0) green: (154.0 / 256.0) blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIBlueColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: (179.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSIMagentaColor
{
  return [NSColor colorWithCalibratedRed: (179.0 / 256.0) green: 0.0 blue: (179.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSICyanColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: (167.0 / 256.0) blue: (179.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSIWhiteColor
{
  return [NSColor colorWithCalibratedRed: (192.0 / 256.0) green: (192.0 / 256.0) blue: (192.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSIBrightBlackColor
{
  return [NSColor colorWithCalibratedRed: (103.0 / 256.0) green: (103.0 / 256.0) blue: (103.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSIBrightRedColor
{
  return [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: 0.0 blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIBrightGreenColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: (218.0 / 256.0) blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIBrightYellowColor
{
  return [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: (230.0 / 256.0) blue: 0.0 alpha: 1.0];
}

+ (NSColor *) ANSIBrightBlueColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
}

+ (NSColor *) ANSIBrightMagentaColor
{
  return [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: 0.0 blue: (230.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSIBrightCyanColor
{
  return [NSColor colorWithCalibratedRed: 0.0 green: (230.0 / 256.0) blue: (230.0 / 256.0) alpha: 1.0];
}

+ (NSColor *) ANSIBrightWhiteColor
{
  return [NSColor colorWithCalibratedRed: (230.0 / 256.0) green: (230.0 / 256.0) blue: (230.0 / 256.0) alpha: 1.0];
}

@end
