//
// MUTerminalConstants.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

typedef NS_ENUM (NSInteger, MUTerminalControlStringType)
{
  MUTerminalControlStringTypeOperatingSystemCommand = 0x9d,
  MUTerminalControlStringTypePrivacyMessage = 0x9e,
  MUTerminalControlStringTypeApplicationProgram = 0x9f
};

typedef NS_ENUM (NSInteger, MUTerminalCSICommand)
{
  MUTerminalCSICursorRight = 0x43,           // 'C'
  MUTerminalCSISelectGraphicRendition = 0x6d // 'm'
};

typedef NS_ENUM (NSInteger, MUANSICode)
{
  MUANSIReset = 0,
  MUANSIBrightOn = 1,
  MUANSIItalicsOn = 3,
  MUANSIUnderlineOn = 4,
  MUANSISlowBlinkOn = 5,
  MUANSIRapidBlinkOn = 6,
  MUANSIInverseOn = 7,
  MUANSIHiddenTextOn = 8,
  MUANSIStrikethroughOn = 9,
  MUANSIDoubleUnderlineOn = 21,
  MUANSIBrightOff = 22,
  MUANSIItalicsOff = 23,
  MUANSIUnderlineOff = 24,
  MUANSIBlinkOff = 25,
  MUANSIInverseOff = 27,
  MUANSIHiddenTextOff = 28,
  MUANSIStrikethroughOff = 29,
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
  MUANSIBackgroundDefault = 49,
  MUANSIForegroundBrightBlack = 90,
  MUANSIForegroundBrightRed = 91,
  MUANSIForegroundBrightGreen = 92,
  MUANSIForegroundBrightYellow = 93,
  MUANSIForegroundBrightBlue = 94,
  MUANSIForegroundBrightMagenta = 95,
  MUANSIForegroundBrightCyan = 96,
  MUANSIForegroundBrightWhite = 97,
  MUANSIBackgroundBrightBlack = 100,
  MUANSIBackgroundBrightRed = 101,
  MUANSIBackgroundBrightGreen = 102,
  MUANSIBackgroundBrightYellow = 103,
  MUANSIBackgroundBrightBlue = 104,
  MUANSIBackgroundBrightMagenta = 105,
  MUANSIBackgroundBrightCyan = 106,
  MUANSIBackgroundBrightWhite = 107
};

typedef NS_ENUM (NSInteger, MUAbstractANSIColor)
{
  MUANSIColorBlack,
  MUANSIColorRed,
  MUANSIColorGreen,
  MUANSIColorYellow,
  MUANSIColorBlue,
  MUANSIColorMagenta,
  MUANSIColorCyan,
  MUANSIColorWhite,
  MUANSIColorBrightBlack,
  MUANSIColorBrightRed,
  MUANSIColorBrightGreen,
  MUANSIColorBrightYellow,
  MUANSIColorBrightBlue,
  MUANSIColorBrightMagenta,
  MUANSIColorBrightCyan,
  MUANSIColorBrightWhite
};

typedef NS_ENUM (NSInteger, MUANSI256ColorCode)
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
};
