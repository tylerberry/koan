//
// MUConstants.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUConstants.h"

#pragma mark Application constants.

NSString * const MUApplicationName = @"Koan";

#pragma mark URLs.

NSString * const MUKoanBugsURLString = @"https://github.com/tylerberry/koan/issues";
NSString * const MUGrowlURLString = @"http://growl.info/";
NSString * const MUOpenSSLURLString = @"http://www.openssl.org/";
NSString * const MUSparkleURLString = @"http://sparkle.andymatuschak.org/";
NSString * const MUUKPrefsPaneURLString = @"http://zathras.de/angelweb/sourcecode.htm";

#pragma mark User defaults constants.

NSString * const MUPBackgroundColor = @"MUPBackgroundColor";
NSString * const MUPFont = @"MUPFont";
NSString * const MUPLinkColor = @"MUPLinkColor";
NSString * const MUPTextColor = @"MUPTextColor";
NSString * const MUPSystemTextColor = @"MUPSystemTextColor";
NSString * const MUPWorlds = @"MUPWorlds";
NSString * const MUPProfiles = @"MUPProfiles";
NSString * const MUPProfilesOutlineViewState = @"MUPProfilesOutlineViewState";
NSString * const MUPProxySettings = @"MUPProxySettings";
NSString * const  const MUPUseProxy = @"MUPUseProxy";

NSString * const MUPPlaySounds = @"MUPPlaySounds";
NSString * const MUPPlayWhenActive = @"MUPPlayWhenActive";
NSString * const MUPSoundChoice = @"MUPSoundChoice";

#pragma mark Custom string attributes.

NSString * const MUBoldFontAttributeName = @"MUBoldFont";
NSString * const MUCustomColorAttributeName = @"MUCustomColor";
NSString * const MUItalicFontAttributeName = @"MUItalicFont";

#pragma mark Notification constants.

NSString * const MUConnectionWindowControllerWillCloseNotification = @"MUConnectionWindowControllerWillCloseNotification";
NSString * const MUConnectionWindowControllerDidReceiveTextNotification = @"MUConnectionWindowControllerDidReceiveTextNotification";
NSString * const MUWorldsDidChangeNotification = @"MUWorldsDidChangeNotification";

#pragma mark Toolbar item constants.

NSString * const MUAddWorldToolbarItem = @"MUAddWorldToolbarItem";
NSString * const MUAddPlayerToolbarItem = @"MUAddPlayerToolbarItem";
NSString * const MUEditSelectedRowToolbarItem = @"MUEditSelectedRowToolbarItem";
NSString * const MURemoveSelectedRowToolbarItem = @"MURemoveSelectedRowToolbarItem";
NSString * const MUEditProfileForSelectedRowToolbarItem = @"MUEditProfileForSelectedRowToolbarItem";
NSString * const MUGoToURLToolbarItem = @"MUGoToURLToolbarItem";

#pragma mark Toolbar item localization constants.

NSString * const MULGoToURL = @"GoToURL";

#pragma mark Undoable actions.

NSString * const MUUndoAddPlayer = @"AddPlayer";
NSString * const MUUndoDeletePlayer = @"DeletePlayer";

NSString * const MUUndoAddWorld = @"AddWorld";
NSString * const MUUndoDeleteWorld = @"DeleteWorld";

#pragma mark Growl localization constants.

NSString * const MUGConnectionOpened = @"GrowlConnectionOpened";
NSString * const MUGConnectionClosed = @"GrowlConnectionClosed";
NSString * const MUGConnectionClosedByServer = @"GrowlConnectionClosedByServer";
NSString * const MUGConnectionClosedByError = @"GrowlConnectionClosedByError";

#pragma mark Status message localization constants.

NSString * const MULConnectionOpening = @"ConnectionOpening";
NSString * const MULConnectionOpen = @"ConnectionOpen";
NSString * const MULConnectionClosed = @"ConnectionClosed";
NSString * const MULConnectionClosedByServer = @"ConnectionClosedByServer";
NSString * const MULConnectionClosedByError = @"ConnectionClosedByError";

#pragma mark Alert panel localization constants.

NSString * const MULOK = @"OK";
NSString * const MULConfirm = @"Confirm";
NSString * const MULQuitImmediately = @"QuitImmediately";
NSString * const MULCancel = @"Cancel";

NSString * const MULConfirmCloseTitle = @"ConfirmCloseTitle";
NSString * const MULConfirmCloseMessage = @"ConfirmCloseMessage";

NSString * const MULConfirmQuitTitleSingular = @"ConfirmQuitTitleSingular";
NSString * const MULConfirmQuitTitlePlural = @"ConfirmQuitTitlePlural";
NSString * const MULConfirmQuitMessage = @"ConfirmQuitMessage";

#pragma mark Preferences localization constants.

NSString * const MULPreferencesWindowName = @"PreferencesWindowName";
NSString * const MULPreferencesFontsAndColors = @"PreferencesFontsAndColors";
NSString * const MULPreferencesProxy = @"PreferencesProxy";
NSString * const MULPreferencesSounds = @"PreferencesSounds";

#pragma mark Miscellaneous localization constants.

NSString * const MULConnect = @"Connect";
NSString * const MULDisconnect = @"Disconnect";

NSString * const MULConnectWithoutLogin = @"ConnectWithoutLogin";

#pragma mark ANSI parsing constants.

NSString * const MUANSIForegroundColorAttributeName = @"MUANSIForegroundColorAttributeName";
NSString * const MUANSIBackgroundColorAttributeName = @"MUANSIBackgroundColorAttributeName";
