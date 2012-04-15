//
// MUANSIFormattingFilter.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUFilter.h"

@protocol MUFormatter;

// All of the below codes are supported except for italics and strike. I am merely documenting them here for
// completeness.  They are not implemented because my survey of mushes indicates that they are not used.

typedef enum MUANSICode
{
  MUANSIReset = 0,
  MUANSIBoldOn = 1,
  MUANSIItalicsOn = 3,
  MUANSIUnderlineOn = 4,
  MUANSIInverseOn = 7,
  MUANSIStrikeOn = 9,
  MUANSIBoldOff = 22,
  MUANSIItalicsOff = 23,
  MUANSIUnderlineOff = 24,
  MUANSIInverseOff = 27,
  MUANSIStrikeOff = 29,
  MUANSIForegroundBlack = 30,
  MUANSIForegroundRed = 31,
  MUANSIForegroundGreen = 32,
  MUANSIForegroundYellow = 33,
  MUANSIForegroundBlue = 34,
  MUANSIForegroundMagenta = 35,
  MUANSIForegroundCyan = 36,
  MUANSIForegroundWhite = 37,
  MUANSIForeground256 = 38,
  MUANSIForegroundDefault = 39,
  MUANSIBackgroundBlack = 40,
  MUANSIBackgroundRed = 41,
  MUANSIBackgroundGreen = 42,
  MUANSIBackgroundYellow = 43,
  MUANSIBackgroundBlue = 44,
  MUANSIBackgroundMagenta = 45,
  MUANSIBackgroundCyan = 46,
  MUANSIBackgroundWhite = 47,
  MUANSIBackground256 = 48,
  MUANSIBackgroundDefault = 49
} MUANSICode;

typedef enum MUANSI256ColorCode
{
  MUANSI256Black = 0,
  MUANSI256Red = 1,
  MUANSI256Green = 2,
  MUANSI256Yellow = 3,
  MUANSI256Blue = 4,
  MUANSI256Magenta = 5,
  MUANSI256Cyan = 6,
  MUANSI256White = 7,
  MUANSI256BrightBlack = 8,
  MUANSI256BrightRed = 9,
  MUANSI256BrightGreen = 10,
  MUANSI256BrightYellow = 11,
  MUANSI256BrightBlue = 12,
  MUANSI256BrightMagenta = 13,
  MUANSI256BrightCyan = 14,
  MUANSI256BrightWhite = 15,
} MUANSI256ColorCode;

@interface MUANSIFormattingFilter : MUFilter
{
  BOOL inCode;
  NSString *ansiCode;
  NSObject <MUFormatter> *formatter;
  NSMutableDictionary *currentAttributes;
}

+ (MUFilter *) filterWithFormatter: (NSObject <MUFormatter> *) newFormatter;

- (id) initWithFormatter: (NSObject <MUFormatter> *) newFormatter;

@end
