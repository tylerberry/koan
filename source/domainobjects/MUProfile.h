//
// MUProfile.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUFilter.h"
#import "MUMUDConnection.h"

@interface MUProfile : NSObject <NSCoding>
{
  NSFont *font;
  NSColor *textColor;
  NSColor *backgroundColor;
  NSColor *linkColor;
  NSColor *visitedLinkColor;
}

@property (strong) MUWorld *world;
@property (strong) MUPlayer *player;
@property (assign) BOOL autoconnect;

@property (readonly) NSString *hostname;
@property (readonly) NSString *loginString;
@property (readonly) NSString *uniqueIdentifier;
@property (readonly) NSString *windowTitle;

@property (readonly) NSFont *effectiveFont;
@property (readonly) NSString *effectiveFontDisplayName;
@property (readonly) NSColor *effectiveTextColor;
@property (readonly) NSColor *effectiveBackgroundColor;
@property (readonly) NSColor *effectiveLinkColor;

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

// Actions.
- (MUFilter *) createLogger;
- (MUMUDConnection *) createNewTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate;
- (BOOL) hasLoginInformation;

@end
