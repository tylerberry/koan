//
// MUConstants.m
//
// Copyright (c) 2012 3James Software.
//

#import "MUConstants.h"

#pragma mark Application constants.

NSString *MUApplicationName = @"Koan";

#pragma mark URLs.

NSString *MUKoanBugsURLString = @"https://github.com/tylerberry/koan/issues";
NSString *MUGrowlURLString = @"http://growl.info/";
NSString *MUOpenSSLURLString = @"http://www.openssl.org/";
NSString *MUSparkleURLString = @"http://sparkle.andymatuschak.org/";
NSString *MUUKPrefsPaneURLString = @"http://zathras.de/angelweb/sourcecode.htm";

#pragma mark User defaults constants.

NSString *MUPBackgroundColor = @"MUPBackgroundColor";
NSString *MUPFontName = @"MUPFontName";
NSString *MUPFontSize = @"MUPFontSize";
NSString *MUPLinkColor = @"MUPLinkColor";
NSString *MUPTextColor = @"MUPTextColor";
NSString *MUPWorlds = @"MUPWorlds";
NSString *MUPProfiles = @"MUPProfiles";
NSString *MUPProfilesOutlineViewState = @"MUPProfilesOutlineViewState";
NSString *MUPVisitedLinkColor = @"MUPVisitedLinkColor";
NSString *MUPProxySettings = @"MUPProxySettings";
NSString *MUPUseProxy = @"MUPUseProxy";

NSString *MUPPlaySounds = @"MUPPlaySounds";
NSString *MUPPlayWhenActive = @"MUPPlayWhenActive";
NSString *MUPSoundChoice = @"MUPSoundChoice";

#pragma mark Custom string attributes.

NSString *MUBoldFontAttributeName = @"MUBoldFont";
NSString *MUCustomColorAttributeName = @"MUCustomColor";
NSString *MUItalicFontAttributeName = @"MUItalicFont";

#pragma mark Notification constants.

NSString *MUConnectionWindowControllerWillCloseNotification = @"MUConnectionWindowControllerWillCloseNotification";
NSString *MUConnectionWindowControllerDidReceiveTextNotification = @"MUConnectionWindowControllerDidReceiveTextNotification";
NSString *MUGlobalBackgroundColorDidChangeNotification = @"MUGlobalBackgroundColorDidChangeNotification";
NSString *MUGlobalFontDidChangeNotification = @"MUGlobalFontDidChangeNotification";
NSString *MUGlobalLinkColorDidChangeNotification = @"MUGlobalLinkColorDidChangeNotification";
NSString *MUGlobalTextColorDidChangeNotification = @"MUGlobalTextColorDidChangeNotification";
NSString *MUGlobalVisitedLinkColorDidChangeNotification = @"MUGlobalVisitedLinkColorDidChangeNotification";
NSString *MUWorldsDidChangeNotification = @"MUWorldsDidChangeNotification";

#pragma mark Toolbar item constants.

NSString *MUAddWorldToolbarItem = @"MUAddWorldToolbarItem";
NSString *MUAddPlayerToolbarItem = @"MUAddPlayerToolbarItem";
NSString *MUEditSelectedRowToolbarItem = @"MUEditSelectedRowToolbarItem";
NSString *MURemoveSelectedRowToolbarItem = @"MURemoveSelectedRowToolbarItem";
NSString *MUEditProfileForSelectedRowToolbarItem = @"MUEditProfileForSelectedRowToolbarItem";
NSString *MUGoToURLToolbarItem = @"MUGoToURLToolbarItem";

#pragma mark Toolbar item localization constants.

NSString *MULGoToURL = @"GoToURL";

#pragma mark Undoable actions.

NSString *MUUndoAddPlayer = @"AddPlayer";
NSString *MUUndoDeletePlayer = @"DeletePlayer";

NSString *MUUndoAddWorld = @"AddWorld";
NSString *MUUndoDeleteWorld = @"DeleteWorld";

#pragma mark Growl localization constants.

NSString *MUGConnectionOpened = @"GrowlConnectionOpened";
NSString *MUGConnectionClosed = @"GrowlConnectionClosed";
NSString *MUGConnectionClosedByServer = @"GrowlConnectionClosedByServer";
NSString *MUGConnectionClosedByError = @"GrowlConnectionClosedByError";

#pragma mark Status message localization constants.

NSString *MULConnectionOpening = @"ConnectionOpening";
NSString *MULConnectionOpen = @"ConnectionOpen";
NSString *MULConnectionClosed = @"ConnectionClosed";
NSString *MULConnectionClosedByServer = @"ConnectionClosedByServer";
NSString *MULConnectionClosedByError = @"ConnectionClosedByError";

#pragma mark Alert panel localization constants.

NSString *MULOK = @"OK";
NSString *MULConfirm = @"Confirm";
NSString *MULQuitImmediately = @"QuitImmediately";
NSString *MULCancel = @"Cancel";

NSString *MULConfirmCloseTitle = @"ConfirmCloseTitle";
NSString *MULConfirmCloseMessage = @"ConfirmCloseMessage";

NSString *MULConfirmQuitTitleSingular = @"ConfirmQuitTitleSingular";
NSString *MULConfirmQuitTitlePlural = @"ConfirmQuitTitlePlural";
NSString *MULConfirmQuitMessage = @"ConfirmQuitMessage";

#pragma mark Miscellaneous localization constants.

NSString *MULFontFullDisplayName = @"FontFullDisplayName";

NSString *MULConnect = @"Connect";
NSString *MULDisconnect = @"Disconnect";

NSString *MULConnectWithoutLogin = @"ConnectWithoutLogin";

#pragma mark Miscellaneous other constants.

NSString *MUInsertionIndex = @"MUInsertionIndex";
NSString *MUInsertionWorld = @"MUInsertionWorld";

#pragma mark ANSI parsing constants.

NSString *MUANSIForegroundColorAttributeName = @"MUANSIForegroundColorAttributeName";
NSString *MUANSIBackgroundColorAttributeName = @"MUANSIBackgroundColorAttributeName";
