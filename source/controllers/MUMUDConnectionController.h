//
// MUMUDConnectionController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUMUDConnection.h"

#import "MUANSIFormattingFilter.h"
#import "MUFugueEditFilter.h"
#import "MUProfile.h"

@protocol MUMUDConnectionControllerDelegate

@required
- (void) clearPrompt;
- (void) displayAttributedString: (NSAttributedString *) attributedString asPrompt: (BOOL) prompt;
- (void) reportWindowSizeToServer;
- (void) startDisplayingTimeConnected;
- (void) stopDisplayingTimeConnected;

@end

#pragma mark -

@interface MUMUDConnectionController : NSObject <MUMUDConnectionDelegate>

@property (weak) NSObject <MUMUDConnectionControllerDelegate> *delegate;
@property (strong, readonly) MUMUDConnection *connection;
@property (strong, readonly) MUProfile *profile;

- (id) initWithProfile: (MUProfile *) newProfile
     fugueEditDelegate: (NSObject <MUFugueEditFilterDelegate> *) fugueEditDelegate;

- (void) connect;
- (void) disconnect;
- (void) echoString: (NSString *) string;
- (void) sendNumberOfWindowLines: (NSUInteger) numberOfLines columns: (NSUInteger) numberOfColumns;
- (void) sendString: (NSString *) string;

@end
