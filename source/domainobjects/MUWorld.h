//
// MUWorld.h
//
// Copyright (c) 2012 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUTreeNode.h"

@class MUMUDConnection;
@class MUPlayer;
@protocol MUMUDConnectionDelegate;

@interface MUWorld : MUTreeNode <NSCoding, NSCopying>

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (copy) NSString *url;
@property (unsafe_unretained, readonly) NSString *uniqueIdentifier;
@property (unsafe_unretained, readonly) NSString *windowTitle;

+ (MUWorld *) worldWithName: (NSString *) newName
  								 hostname: (NSString *) newHostname
  										 port: (NSNumber *) newPort
  											URL: (NSString *) newURL
  									players: (NSArray *) newPlayers;

+ (MUWorld *) worldWithHostname: (NSString *) newHostname
                           port: (NSNumber *) newPort;

// Designated initializer.
- (id) initWithName: (NSString *) newName
           hostname: (NSString *) newHostname
               port: (NSNumber *) newPort
                URL: (NSString *) newURL
            players: (NSArray *) newPlayers;

- (id) initWithHostname: (NSString *) newHostname
                   port: (NSNumber *) newPort;

// Actions.
- (MUMUDConnection *) newTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

@end
