//
// MUConstants.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#pragma mark Application constants.

extern NSString *MUApplicationName;

#pragma mark URLs.

extern NSString *MUKoanBugsURLString;
extern NSString *MUGrowlURLString;
extern NSString *MUOpenSSLURLString;
extern NSString *MUSparkleURLString;
extern NSString *MUUKPrefsPaneURLString;

#pragma mark User defaults constants.

extern NSString *MUPBackgroundColor;
extern NSString *MUPFont;
extern NSString *MUPLinkColor;
extern NSString *MUPTextColor;
extern NSString *MUPWorlds;
extern NSString *MUPProfiles;
extern NSString *MUPProfilesOutlineViewState;
extern NSString *MUPSystemTextColor;
extern NSString *MUPProxySettings;
extern NSString *MUPUseProxy;

extern NSString *MUPPlaySounds;
extern NSString *MUPPlayWhenActive;
extern NSString *MUPSoundChoice;

#pragma mark Custom string attributes.

extern NSString *MUBoldFontAttributeName;
extern NSString *MUCustomColorAttributeName;
extern NSString *MUItalicFontAttributeName;

#pragma mark Notification constants.

extern NSString *MUConnectionWindowControllerWillCloseNotification;
extern NSString *MUConnectionWindowControllerDidReceiveTextNotification;
extern NSString *MUWorldsDidChangeNotification;

extern NSString *MUReadBufferDidProvideStringNotification;

#pragma mark Toolbar item constants.

extern NSString *MUAddWorldToolbarItem;
extern NSString *MUAddPlayerToolbarItem;
extern NSString *MUEditSelectedRowToolbarItem;
extern NSString *MURemoveSelectedRowToolbarItem;
extern NSString *MUEditProfileForSelectedRowToolbarItem;
extern NSString *MUGoToURLToolbarItem;

#pragma mark Toolbar item localization constants.

extern NSString *MULGoToURL;

#pragma mark Undoable actions.

extern NSString *MUUndoAddPlayer;
extern NSString *MUUndoDeletePlayer;

extern NSString *MUUndoAddWorld;
extern NSString *MUUndoDeleteWorld;

#pragma mark Growl constants.

extern NSString *MUGConnectionOpened;
extern NSString *MUGConnectionClosed;
extern NSString *MUGConnectionClosedByServer;
extern NSString *MUGConnectionClosedByError;

#pragma mark Status message localization constants.

extern NSString *MULConnectionOpening;
extern NSString *MULConnectionOpen;
extern NSString *MULConnectionClosed;
extern NSString *MULConnectionClosedByServer;
extern NSString *MULConnectionClosedByError;

#pragma mark Preferences localization constants.

extern NSString *MULPreferencesWindowName;
extern NSString *MULPreferencesFontsAndColors;
extern NSString *MULPreferencesProxy;
extern NSString *MULPreferencesSounds;

#pragma mark Alert panel localization constants.

extern NSString *MULOK;
extern NSString *MULConfirm;
extern NSString *MULQuitImmediately;
extern NSString *MULCancel;

extern NSString *MULConfirmCloseTitle;
extern NSString *MULConfirmCloseMessage;

extern NSString *MULConfirmQuitTitleSingular;
extern NSString *MULConfirmQuitTitlePlural;
extern NSString *MULConfirmQuitMessage;

#pragma mark Miscellaneous localization constants.

extern NSString *MULConnect;
extern NSString *MULDisconnect;

extern NSString *MULConnectWithoutLogin;

#pragma mark Miscellaneous other constants.

extern NSString *MUInsertionIndex;
extern NSString *MUInsertionWorld;

#pragma mark ANSI parsing constants

extern NSString *MUANSIForegroundColorAttributeName;
extern NSString *MUANSIBackgroundColorAttributeName;
