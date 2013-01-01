//
// MUWorld.h
//
// Copyright (c) 2013 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUTreeNode.h"

@class MUMUDConnection;
@class MUPlayer;
@protocol MUMUDConnectionDelegate;

@interface MUWorld : MUTreeNode

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (copy) NSString *url;
@property (readonly) NSString *windowTitle;

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
