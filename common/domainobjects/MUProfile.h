//
// MUProfile.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUWorld.h"
#import "MUPlayer.h"
#import "MUFilter.h"

@class MUMUDConnection;
@protocol MUFugueEditFilterDelegate;

@interface MUProfile : NSObject <NSSecureCoding>

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

+ (NSArray <NSString *> *) writableProperties;

+ (instancetype) profileWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
+ (instancetype) profileWithWorld: (MUWorld *) newWorld;

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithWorld: (MUWorld *) newWorld
                        player: (MUPlayer *) newPlayer
                   autoconnect: (BOOL) newAutoconnect
                          font: (NSFont *) newFont
               backgroundColor: (NSColor *) newBackgroundColor
                     linkColor: (NSColor *) newLinkColor
               systemTextColor: (NSColor *) newSystemTextColor
                     textColor: (NSColor *) newTextColor NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithWorld: (MUWorld *) newWorld player: (MUPlayer *) newPlayer;
- (instancetype) initWithWorld: (MUWorld *) newWorld;

// Actions.
- (MUFilter *) createLogger;
- (MUMUDConnection *) createNewMUDConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate, MUFugueEditFilterDelegate> *) delegate;

@end
