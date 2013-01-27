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

+ (MUConnectionWindowControllerRegistry *) defaultRegistry;

- (MUConnectionWindowController *) controllerForProfile: (MUProfile *) profile;
- (MUConnectionWindowController *) controllerForWorld: (MUWorld *) world;

@end
