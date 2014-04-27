//
// MUTerminalConstants.h
//
// Copyright (c) 2014 3James Software. All rights reserved.
//

enum MUTerminalControlStringTypes
{
  MUTerminalControlStringTypeOperatingSystemCommand = 0,
  MUTerminalControlStringTypePrivacyMessage = 1,
  MUTerminalControlStringTypeApplicationProgram = 2
};

typedef enum MUANSICode
{
  MUANSIReset = 0,
  MUANSIBoldOn = 1,
  MUANSIItalicsOn = 3,
  MUANSIUnderlineOn = 4,
  MUANSISlowBlinkOn = 5,
  MUANSIRapidBlinkOn = 6,
  MUANSIInverseOn = 7,
  MUANSIHiddenTextOn = 8,
  MUANSIStrikethroughOn = 9,
  MUANSIDoubleUnderlineOn = 21,
  MUANSIBoldOff = 22,
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
