//
// MUWorld.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUTreeNode.h"

@class MUMUDConnection;
@class MUPlayer;
@protocol J3LineBufferDelegate;
@protocol MUMUDConnectionDelegate;

@interface MUWorld : MUTreeNode <NSCoding, NSCopying>
{
  NSString *hostname;
  NSNumber *port;
  NSString *url;
}

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (copy) NSString *url;
@property (readonly) NSString *uniqueIdentifier;
@property (readonly) NSString *windowTitle;

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
