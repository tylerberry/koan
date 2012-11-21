//
// MUConstants.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#pragma mark Application constants.

extern NSString * const MUApplicationName;

#pragma mark URLs.

extern NSString * const MUKoanBugsURLString;
extern NSString * const MUGrowlURLString;
extern NSString * const MUOpenSSLURLString;
extern NSString * const MUSparkleURLString;
extern NSString * const MUUKPrefsPaneURLString;

#pragma mark User defaults constants.

extern NSString * const MUPBackgroundColor;
extern NSString * const MUPFont;
extern NSString * const MUPLinkColor;
extern NSString * const MUPTextColor;
extern NSString * const MUPWorlds;
extern NSString * const MUPProfiles;
extern NSString * const MUPProfilesOutlineViewState;
extern NSString * const MUPSystemTextColor;
extern NSString * const MUPProxySettings;
extern NSString * const MUPUseProxy;

extern NSString * const MUPPlaySounds;
extern NSString * const MUPPlayWhenActive;
extern NSString * const MUPSoundChoice;

#pragma mark Custom string attributes.

extern NSString * const MUBoldFontAttributeName;
extern NSString * const MUCustomColorAttributeName;
extern NSString * const MUItalicFontAttributeName;

#pragma mark Notification constants.

extern NSString * const MUConnectionWindowControllerWillCloseNotification;
extern NSString * const MUConnectionWindowControllerDidReceiveTextNotification;
extern NSString * const MUWorldsDidChangeNotification;

extern NSString * const MUReadBufferDidProvideStringNotification;

#pragma mark Toolbar item constants.

extern NSString * const MUAddWorldToolbarItem;
extern NSString * const MUAddPlayerToolbarItem;
extern NSString * const MUEditSelectedRowToolbarItem;
extern NSString * const MURemoveSelectedRowToolbarItem;
extern NSString * const MUEditProfileForSelectedRowToolbarItem;
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

#pragma mark Preferences localization constants.

extern NSString * const MULPreferencesWindowName;
extern NSString * const MULPreferencesFontsAndColors;
extern NSString * const MULPreferencesProxy;
extern NSString * const MULPreferencesSounds;

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

#pragma mark ANSI parsing constants

extern NSString * const MUANSIForegroundColorAttributeName;
extern NSString * const MUANSIBackgroundColorAttributeName;
