//
// MUWorld.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUTreeNode.h"

@class MUPlayer;
@protocol MUMUDConnectionDelegate;

@interface MUWorld : MUTreeNode

@property (copy) NSString *hostname;
@property (copy) NSNumber *port;
@property (assign) BOOL forceTLS;
@property (copy) NSString *url;
@property (readonly) NSString *windowTitle;

+ (MUWorld *) worldWithName: (NSString *) name
                   hostname: (NSString *) hostname
                       port: (NSNumber *) port
                   forceTLS: (BOOL) forceTLS
                        URL: (NSString *) url
                   children: (NSArray *) children;

+ (MUWorld *) worldWithHostname: (NSString *) hostname
                           port: (NSNumber *) port
                       forceTLS: (BOOL) forceTLS;

// Designated initializer.
- (id) initWithName: (NSString *) name
           hostname: (NSString *) hostname
               port: (NSNumber *) port
           forceTLS: (BOOL) forceTLS
                URL: (NSString *) url
           children: (NSArray *) children;

- (id) initWithHostname: (NSString *) hostname
                   port: (NSNumber *) port
               forceTLS: (BOOL) forceTLS;

@end
