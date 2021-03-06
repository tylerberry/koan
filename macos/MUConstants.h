//
// MUConstants.h
//
// Copyright (c) 2013 3James Software.
//

#pragma mark Application constants.

extern NSString * const MUApplicationName;

#pragma mark URLs.

extern NSString * const MUKoanBugsURLString;
extern NSString * const MUGrowlURLString;
extern NSString * const MUOpenSSLURLString;
extern NSString * const MUSparkleURLString;

#pragma mark User defaults constants.

// Stuff stored in user defaults that isn't in preferences exactly.

extern NSString * const MUPWorlds;
extern NSString * const MUPProfiles;
extern NSString * const MUPProfilesOutlineViewState;

// General.

extern NSString * const MUPAutomaticReconnect;
extern NSString * const MUPLimitAutomaticReconnect;
extern NSString * const MUPAutomaticReconnectCount;
extern NSString * const MUPDropDuplicateLines;
extern NSString * const MUPDropDuplicateLinesCount;

// Sounds.

extern NSString * const MUPPlaySounds;
extern NSString * const MUPPlayWhenActive;
extern NSString * const MUPSoundChoice;
extern NSString * const MUPSoundVolume;

// Fonts.

extern NSString * const MUPFont;
extern NSString * const MUPDefaultFontChangeBehavior;

#define MUPDefaultFontChangeUpdateDefault @0
#define MUPDefaultFontChangeCustomFontForProfile @1
#define MUPDefaultFontChangeAsk @2

// Colors.

extern NSString * const MUPBackgroundColor;
extern NSString * const MUPLinkColor;
extern NSString * const MUPSystemTextColor;
extern NSString * const MUPTextColor;

extern NSString * const MUPANSIBlackColor;
extern NSString * const MUPANSIRedColor;
extern NSString * const MUPANSIGreenColor;
extern NSString * const MUPANSIYellowColor;
extern NSString * const MUPANSIBlueColor;
extern NSString * const MUPANSIMagentaColor;
extern NSString * const MUPANSICyanColor;
extern NSString * const MUPANSIWhiteColor;

extern NSString * const MUPANSIBrightBlackColor;
extern NSString * const MUPANSIBrightRedColor;
extern NSString * const MUPANSIBrightGreenColor;
extern NSString * const MUPANSIBrightYellowColor;
extern NSString * const MUPANSIBrightBlueColor;
extern NSString * const MUPANSIBrightMagentaColor;
extern NSString * const MUPANSIBrightCyanColor;
extern NSString * const MUPANSIBrightWhiteColor;

extern NSString * const MUPDisplayBrightAsBold;

// Logging.

extern NSString * const MUPLogDirectoryURL;

// Proxy.

extern NSString * const MUPProxySettings;
extern NSString * const MUPUseProxy;

// Conditions.

extern NSString * const MUPConditions;

#define MUPProxyNone @0
#define MUPProxySystem @1
#define MUPProxyCustom @2

#pragma mark Custom string attributes.

extern NSString * const MUBrightColorAttributeName;
extern NSString * const MUItalicFontAttributeName;
extern NSString * const MUInverseColorsAttributeName;

extern NSString * const MUBlinkingTextAttributeName;
extern NSString * const MUHiddenTextAttributeName;

#define MUSlowBlink 1
#define MURapidBlink 2

extern NSString * const MUCustomForegroundColorAttributeName;
extern NSString * const MUCustomBackgroundColorAttributeName;

#pragma mark Custom color tags.

typedef NS_ENUM(NSInteger, MUColorTag)
{
  MUColorTagUndefined = -1,
  MUColorTagDefaultForeground = 0,
  MUColorTagDefaultBackground,
  MUColorTagSystemText,
  MUColorTagANSIBlack,
  MUColorTagANSIRed,
  MUColorTagANSIGreen,
  MUColorTagANSIYellow,
  MUColorTagANSIBlue,
  MUColorTagANSICyan,
  MUColorTagANSIMagenta,
  MUColorTagANSIWhite,
  MUColorTagANSIBrightBlack,
  MUColorTagANSIBrightRed,
  MUColorTagANSIBrightGreen,
  MUColorTagANSIBrightYellow,
  MUColorTagANSIBrightBlue,
  MUColorTagANSIBrightCyan,
  MUColorTagANSIBrightMagenta,
  MUColorTagANSIBrightWhite,
  MUColorTagANSI256Black,      // ANSI-256 colors are distinct from ANSI-16 colors in that they're not affected by the
  MUColorTagANSI256Red,        // bright conversion. If ANSI-256 is used to specify a non-bright color, that color stays
  MUColorTagANSI256Green,      // non-bright regardless of other ANSI attributes.
  MUColorTagANSI256Yellow,
  MUColorTagANSI256Blue,
  MUColorTagANSI256Cyan,
  MUColorTagANSI256Magenta,
  MUColorTagANSI256White,
  MUColorTagANSI256Fixed
};

#pragma mark Pasteboard type constants.

extern NSString * const MUPlayerPasteboardType;
extern NSString * const MUWorldPasteboardType;

#pragma mark Notification constants.

extern NSString * const MUConnectionWindowControllerWillCloseNotification;
extern NSString * const MUConnectionWindowControllerDidReceiveTextNotification;
extern NSString * const MUWorldsDidChangeNotification;

#pragma mark Toolbar item constants.

extern NSString * const MUGoToURLToolbarItem;

#pragma mark Toolbar item localization constants.

extern NSString * const MULGoToURL;

#pragma mark Undoable actions.

extern NSString * const MUUndoAddPlayer;
extern NSString * const MUUndoDeletePlayer;

extern NSString * const MUUndoAddWorld;
extern NSString * const MUUndoDeleteWorld;

#pragma mark Growl constants.

extern NSString * const MUGConnectionOpened;
extern NSString * const MUGConnectionClosed;
extern NSString * const MUGConnectionClosedByServer;
extern NSString * const MUGConnectionClosedByError;

#pragma mark Status message localization constants.

extern NSString * const MULConnectionOpening;
extern NSString * const MULConnectionOpen;
extern NSString * const MULConnectionClosed;
extern NSString * const MULConnectionClosedByServer;
extern NSString * const MULConnectionClosedByError;
extern NSString * const MULConnectionNoErrorAvailable;

#pragma mark Preferences localization constants.

extern NSString * const MULPreferencesWindowName;
extern NSString * const MULPreferencesConditions;
extern NSString * const MULPreferencesFontsAndColors;
extern NSString * const MULPreferencesGeneral;
extern NSString * const MULPreferencesLogging;
extern NSString * const MULPreferencesProxy;
extern NSString * const MULPreferencesSounds;
extern NSString * const MULPreferencesChooseAnotherSound;
extern NSString * const MULPreferencesChooseAnotherLocation;

#pragma mark Alert panel localization constants.

extern NSString * const MULOK;
extern NSString * const MULConfirm;
extern NSString * const MULQuitImmediately;
extern NSString * const MULCancel;

extern NSString * const MULConfirmCloseTitle;
extern NSString * const MULConfirmCloseMessage;

extern NSString * const MULConfirmQuitTitleSingular;
extern NSString * const MULConfirmQuitTitlePlural;
extern NSString * const MULConfirmQuitMessage;

#pragma mark Miscellaneous localization constants.

extern NSString * const MULConnect;
extern NSString * const MULDisconnect;

extern NSString * const MULConnectWithoutLogin;

extern NSString * const MULNoProfileSelected;
