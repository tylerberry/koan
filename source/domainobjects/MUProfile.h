//
// MUProfile.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUFormatter.h"
#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUFilter.h"
#import "MUMUDConnection.h"

@interface MUProfile : NSObject <NSCoding>
{
  BOOL loggedIn;
  
  NSFont *font;
  NSColor *textColor;
  NSColor *backgroundColor;
  NSColor *linkColor;
  NSColor *visitedLinkColor;
}

@property (strong) MUWorld *world;
@property (strong) MUPlayer *player;
@property (assign) BOOL autoconnect;
@property (unsafe_unretained, readonly) NSString *hostname;
@property (unsafe_unretained, readonly) NSString *loginString;
@property (unsafe_unretained, readonly) NSString *uniqueIdentifier;
@property (unsafe_unretained, readonly) NSString *windowTitle;

+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld
                          player: (MUPlayer *) newPlayer
                     autoconnect: (BOOL) autoconnect;
+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld;

// Designated initializer.
- (id) initWithWorld: (MUWorld *) newWorld
              player: (MUPlayer *) newPlayer
         autoconnect: (BOOL) newAutoconnect
  							font: (NSFont *) newFont
  				 textColor: (NSColor *) newTextColor
  	 backgroundColor: (NSColor *) newBackgroundColor
  				 linkColor: (NSColor *) newLinkColor
  	visitedLinkColor: (NSColor *) newVisitedLinkColor;

- (id) initWithWorld: (MUWorld *) newWorld
              player: (MUPlayer *) newPlayer
         autoconnect: (BOOL) newAutoconnect;

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
- (id) initWithWorld: (MUWorld *) newWorld;

// Accessors.
- (NSFont *) font;
- (void) setFont: (NSFont *) newFont;
- (NSColor *) textColor;
- (void) setTextColor: (NSColor *) newTextColor;
- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *) newBackgroundColor;
- (NSColor *) linkColor;
- (void) setLinkColor: (NSColor *) newLinkColor;
- (NSColor *) visitedLinkColor;
- (void) setVisitedLinkColor: (NSColor *) newVisitedLinkColor;
- (NSObject <MUFormatter> *) formatter;

// Derived bindings.
- (NSFont *) effectiveFont;
- (NSString *) effectiveFontDisplayName;
- (NSData *) effectiveTextColor;
- (NSData *) effectiveBackgroundColor;
- (NSData *) effectiveLinkColor;
- (NSData *) effectiveVisitedLinkColor;

// Actions.
- (MUFilter *) createLogger;
- (MUMUDConnection *) createNewTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate;
- (BOOL) hasLoginInformation;

@end
