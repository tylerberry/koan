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
  MUTerminalCSICommandCursorRight = 0x43,           // 'C'
  MUTerminalCSICommandSelectGraphicRendition = 0x6d // 'm'
};

typedef NS_ENUM (NSInteger, MUANSICode)
{
  MUANSICodeReset = 0,
  MUANSICodeBrightOn = 1,
  MUANSICodeItalicsOn = 3,
  MUANSICodeUnderlineOn = 4,
  MUANSICodeSlowBlinkOn = 5,
  MUANSICodeRapidBlinkOn = 6,
  MUANSICodeInverseOn = 7,
  MUANSICodeHiddenTextOn = 8,
  MUANSICodeStrikethroughOn = 9,
  MUANSICodeDoubleUnderlineOn = 21,
  MUANSICodeBrightOff = 22,
  MUANSICodeItalicsOff = 23,
  MUANSICodeUnderlineOff = 24,
  MUANSICodeBlinkOff = 25,
  MUANSICodeInverseOff = 27,
  MUANSICodeHiddenTextOff = 28,
  MUANSICodeStrikethroughOff = 29,
  MUANSICodeForegroundBlack = 30,
  MUANSICodeForegroundRed = 31,
  MUANSICodeForegroundGreen = 32,
  MUANSICodeForegroundYellow = 33,
  MUANSICodeForegroundBlue = 34,
  MUANSICodeForegroundMagenta = 35,
  MUANSICodeForegroundCyan = 36,
  MUANSICodeForegroundWhite = 37,
  MUANSICodeForeground256 = 38,
  MUANSICodeForegroundDefault = 39,
  MUANSICodeBackgroundBlack = 40,
  MUANSICodeBackgroundRed = 41,
  MUANSICodeBackgroundGreen = 42,
  MUANSICodeBackgroundYellow = 43,
  MUANSICodeBackgroundBlue = 44,
  MUANSICodeBackgroundMagenta = 45,
  MUANSICodeBackgroundCyan = 46,
  MUANSICodeBackgroundWhite = 47,
  MUANSICodeBackground256 = 48,
  MUANSICodeBackgroundDefault = 49,
  MUANSICodeForegroundBrightBlack = 90,
  MUANSICodeForegroundBrightRed = 91,
  MUANSICodeForegroundBrightGreen = 92,
  MUANSICodeForegroundBrightYellow = 93,
  MUANSICodeForegroundBrightBlue = 94,
  MUANSICodeForegroundBrightMagenta = 95,
  MUANSICodeForegroundBrightCyan = 96,
  MUANSICodeForegroundBrightWhite = 97,
  MUANSICodeBackgroundBrightBlack = 100,
  MUANSICodeBackgroundBrightRed = 101,
  MUANSICodeBackgroundBrightGreen = 102,
  MUANSICodeBackgroundBrightYellow = 103,
  MUANSICodeBackgroundBrightBlue = 104,
  MUANSICodeBackgroundBrightMagenta = 105,
  MUANSICodeBackgroundBrightCyan = 106,
  MUANSICodeBackgroundBrightWhite = 107
};

typedef NS_ENUM (NSInteger, MUAbstractANSIColor)
{
  MUAbstractANSIColorBlack,
  MUAbstractANSIColorRed,
  MUAbstractANSIColorGreen,
  MUAbstractANSIColorYellow,
  MUAbstractANSIColorBlue,
  MUAbstractANSIColorMagenta,
  MUAbstractANSIColorCyan,
  MUAbstractANSIColorWhite,
  MUAbstractANSIColorBrightBlack,
  MUAbstractANSIColorBrightRed,
  MUAbstractANSIColorBrightGreen,
  MUAbstractANSIColorBrightYellow,
  MUAbstractANSIColorBrightBlue,
  MUAbstractANSIColorBrightMagenta,
  MUAbstractANSIColorBrightCyan,
  MUAbstractANSIColorBrightWhite
};

typedef NS_ENUM (NSInteger, MUANSI256ColorCode)
{
  MUANSI256ColorCodeBlack = 0,
  MUANSI256ColorCodeRed = 1,
  MUANSI256ColorCodeGreen = 2,
  MUANSI256ColorCodeYellow = 3,
  MUANSI256ColorCodeBlue = 4,
  MUANSI256ColorCodeMagenta = 5,
  MUANSI256ColorCodeCyan = 6,
  MUANSI256ColorCodeWhite = 7,
  MUANSI256ColorCodeBrightBlack = 8,
  MUANSI256ColorCodeBrightRed = 9,
  MUANSI256ColorCodeBrightGreen = 10,
  MUANSI256ColorCodeBrightYellow = 11,
  MUANSI256ColorCodeBrightBlue = 12,
  MUANSI256ColorCodeBrightMagenta = 13,
  MUANSI256ColorCodeBrightCyan = 14,
  MUANSI256ColorCodeBrightWhite = 15,
};
