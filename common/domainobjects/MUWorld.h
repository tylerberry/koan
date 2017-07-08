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

+ (instancetype) worldWithName: (NSString *) name
                      hostname: (NSString *) hostname
                          port: (NSNumber *) port
                      forceTLS: (BOOL) forceTLS
                           URL: (NSString *) url
                      children: (NSArray *) children;

+ (instancetype) worldWithHostname: (NSString *) hostname
                              port: (NSNumber *) port
                          forceTLS: (BOOL) forceTLS;

- (instancetype) initWithCoder: (NSCoder *) decoder NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithName: (NSString *) name children: (NSArray *) children NS_UNAVAILABLE;

- (instancetype) initWithName: (NSString *) name
                     hostname: (NSString *) hostname
                         port: (NSNumber *) port
                     forceTLS: (BOOL) forceTLS
                          URL: (NSString *) url
                     children: (NSArray *) children NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithHostname: (NSString *) hostname
                             port: (NSNumber *) port
                         forceTLS: (BOOL) forceTLS;

@end
