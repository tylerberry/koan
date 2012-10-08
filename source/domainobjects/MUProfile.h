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

@property (strong) NSFont *font;

@property (copy) NSColor *backgroundColor;
@property (copy) NSColor *linkColor;
@property (copy) NSColor *textColor;
@property (copy) NSColor *visitedLinkColor;

@property (strong) MUWorld *world;
@property (strong) MUPlayer *player;
@property (assign) BOOL autoconnect;

@property (readonly) NSFont *effectiveFont;
@property (readonly) NSString *effectiveFontDisplayName;

@property (readonly) NSColor *effectiveTextColor;
@property (readonly) NSColor *effectiveBackgroundColor;
@property (readonly) NSColor *effectiveLinkColor;

@property (readonly) BOOL hasLoginInformation;
@property (readonly) NSString *hostname;
@property (readonly) NSString *loginString;
@property (readonly) NSString *uniqueIdentifier;
@property (readonly) NSString *windowTitle;

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

// Actions.
- (MUFilter *) createLogger;
- (MUMUDConnection *) createNewTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

@end
