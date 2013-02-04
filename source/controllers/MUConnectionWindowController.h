//
// MUConnectionWindowController.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUANSIFormattingFilter.h"
#import "MUFilterQueue.h"
#import "MUFugueEditFilter.h"
#import "MUHistoryRing.h"
#import "MUMUDConnectionController.h"
#import "MUTextView.h"

@protocol MUConnectionWindowControllerDelegate

@optional
- (void) connectionWindowControllerWillClose: (NSNotification *) notification;
- (void) connectionWindowControllerDidReceiveText: (NSNotification *) notification;

@end

#pragma mark -

@interface MUConnectionWindowController : NSWindowController <MUFugueEditFilterDelegate, MUMUDConnectionControllerDelegate, MUTextViewPasteDelegate, NSSplitViewDelegate, NSTextViewDelegate, NSWindowDelegate>
{
  IBOutlet MUTextView *receivedTextView;
  IBOutlet MUTextView *inputView;
  IBOutlet NSSplitView *splitView;
  
  IBOutlet NSTextField *timeConnectedField;
}

@property (weak, nonatomic) NSObject <MUConnectionWindowControllerDelegate> *delegate;
@property (readonly) MUMUDConnectionController *connectionController;

// Designated initializer.
- (id) initWithProfile: (MUProfile *) newProfile;

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
- (id) initWithWorld: (MUWorld *) newWorld;

- (void) confirmClose: (SEL) callback;

- (IBAction) clearWindow: (id) sender;
- (IBAction) connect: (id) sender;
- (IBAction) connectOrDisconnect: (id) sender;
- (IBAction) disconnect: (id) sender;
- (IBAction) goToWorldURL: (id) sender;
- (IBAction) nextCommand: (id) sender;
- (IBAction) previousCommand: (id) sender;
- (IBAction) sendInputText: (id) sender;

@end
