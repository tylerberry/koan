//
// MUProfile.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUFilter.h"
#import "MUMUDConnection.h"

@interface MUProfile : NSObject <NSCoding>

@property (strong) MUWorld *world;
@property (strong) MUPlayer *player;

@property (copy) NSFont *font;

@property (copy) NSColor *backgroundColor;
@property (copy) NSColor *linkColor;
@property (copy) NSColor *systemTextColor;
@property (copy) NSColor *textColor;

@property (assign) BOOL autoconnect;

@property (readonly) NSFont *effectiveFont;

@property (readonly) NSColor *effectiveBackgroundColor;
@property (readonly) NSColor *effectiveLinkColor;
@property (readonly) NSColor *effectiveSystemTextColor;
@property (readonly) NSColor *effectiveTextColor;

@property (readonly) BOOL hasLoginInformation;
@property (readonly) NSString *hostname;
@property (readonly) NSString *loginString;
@property (readonly) NSString *uniqueIdentifier;
@property (readonly) NSString *windowTitle;

@property (readonly) NSArray *writableProperties;

+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
+ (MUProfile *) profileWithWorld: (MUWorld *) newWorld;

// Designated initializer.
- (id) initWithWorld: (MUWorld *) newWorld
              player: (MUPlayer *) newPlayer
         autoconnect: (BOOL) newAutoconnect
                font: (NSFont *) newFont
     backgroundColor: (NSColor *) newBackgroundColor
           linkColor: (NSColor *) newLinkColor
     systemTextColor: (NSColor *) newSystemTextColor
           textColor: (NSColor *) newTextColor;

- (id) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
- (id) initWithWorld: (MUWorld *) newWorld;

// Actions.
- (MUFilter *) createLogger;
- (MUMUDConnection *) createNewTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

@end
