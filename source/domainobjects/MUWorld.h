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
@property (readonly) NSString *windowTitle;

// This is a "fake" property that is triggered when a child object's properties have changed, but the actual child
// objects have not been modified. It has no value of its own. It is used to notify objects that are interested in these
// changes without forcing a reread of the entire MUTreeNode substructure.
@property (readonly) void childProperties;

@property (readonly) NSArray *writableProperties;

+ (MUWorld *) worldWithName: (NSString *) name
                   hostname: (NSString *) hostname
                       port: (NSNumber *) port
                        URL: (NSString *) url
                   children: (NSArray *) children;

+ (MUWorld *) worldWithHostname: (NSString *) hostname
                           port: (NSNumber *) port;

// Designated initializer.
- (id) initWithName: (NSString *) name
           hostname: (NSString *) hostname
               port: (NSNumber *) port
                URL: (NSString *) url
           children: (NSArray *) children;

- (id) initWithHostname: (NSString *) hostname
                   port: (NSNumber *) port;

// Actions.
- (MUMUDConnection *) newTelnetConnectionWithDelegate: (NSObject <MUMUDConnectionDelegate> *) delegate;

@end
