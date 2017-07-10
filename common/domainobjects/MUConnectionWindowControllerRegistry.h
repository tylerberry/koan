//
// MUConnectionWindowControllerRegistry.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectionWindowController.h"
#import "MUProfile.h"

@interface MUConnectionWindowControllerRegistry : NSObject

@property (copy) NSMutableSet *controllers;

@property (readonly) NSUInteger count;
@property (readonly) NSUInteger connectedCount;

+ (instancetype) defaultRegistry;

- (instancetype) init NS_DESIGNATED_INITIALIZER;

- (MUConnectionWindowController *) controllerForProfile: (MUProfile *) profile;
- (MUConnectionWindowController *) controllerForWorld: (MUWorld *) world;

@end
