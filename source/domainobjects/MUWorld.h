//
// MUWorld.h
//
// Copyright (c) 2010 3James Software.
//

#import <Cocoa/Cocoa.h>

@class J3TelnetConnection;
@class MUPlayer;
@protocol J3LineBufferDelegate;
@protocol J3TelnetConnectionDelegate;

@interface MUWorld : NSObject <NSCoding, NSCopying>
{
  NSString *name;
  NSString *hostname;
  NSNumber *port;
  NSString *url;
  BOOL isExpanded;
  NSMutableArray *players;
}

@property (copy) NSString *name;
@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (copy) NSString *url;
@property (assign) BOOL isExpanded;
@property (copy) NSMutableArray *players;
@property (readonly) NSString *uniqueIdentifier;
@property (readonly) NSString *windowTitle;

+ (MUWorld *) worldWithName: (NSString *) newName
  								 hostname: (NSString *) newHostname
  										 port: (NSNumber *) newPort
  											URL: (NSString *) newURL
  									players: (NSArray *) newPlayers;

// Designated initializer.
- (id) initWithName: (NSString *) newName
           hostname: (NSString *) newHostname
               port: (NSNumber *) newPort
                URL: (NSString *) newURL
            players: (NSArray *) newPlayers;

// Array-like functions.
- (void) addPlayer: (MUPlayer *) player;
- (BOOL) containsPlayer: (MUPlayer *) player;
- (int) indexOfPlayer: (MUPlayer *) player;
- (void) insertObject: (MUPlayer *) player inPlayersAtIndex: (unsigned) playerIndex;
- (void) removeObjectFromPlayersAtIndex: (unsigned) playerIndex;
- (void) removePlayer: (MUPlayer *) player;
- (void) replacePlayer: (MUPlayer *) oldPlayer withPlayer: (MUPlayer *) newPlayer;

// Actions.
- (J3TelnetConnection *) newTelnetConnectionWithDelegate: (NSObject <J3TelnetConnectionDelegate> *) delegate;

@end
