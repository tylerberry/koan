//
// MUConnectionWindowController.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUFilterQueue.h"
#import "MUFugueEditFilter.h"
#import "MUHistoryRing.h"
#import "MUProfile.h"
#import "MUTextView.h"

@protocol MUConnectionWindowControllerDelegate

- (void) connectionWindowControllerWillClose: (NSNotification *) notification;
- (void) connectionWindowControllerDidReceiveText: (NSNotification *) notification;

@end

#pragma mark -

@interface MUConnectionWindowController : NSWindowController <MUFugueEditFilterDelegate, MUMUDConnectionDelegate, MUTextViewPasteDelegate, NSSplitViewDelegate, NSTextViewDelegate, NSWindowDelegate>
{
  IBOutlet MUTextView *receivedTextView;
  IBOutlet MUTextView *inputView;
  IBOutlet NSSplitView *splitView;
  
  NSObject <MUConnectionWindowControllerDelegate> *delegate;
  
  MUProfile *profile;
  MUMUDConnection *telnetConnection;
  
  BOOL currentlySearching;
  
  NSTimer *pingTimer;
  MUFilterQueue *filterQueue;
  MUHistoryRing *historyRing;
  
  NSString *currentPrompt;
}

@property (readonly) BOOL isConnectedOrConnecting;

// Designated initializer.
- (id) initWithProfile: (MUProfile *) newProfile;

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
- (id) initWithWorld: (MUWorld *) newWorld;

- (NSObject <MUConnectionWindowControllerDelegate> *) delegate;
- (void) setDelegate: (NSObject <MUConnectionWindowControllerDelegate> *) delegate;

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
