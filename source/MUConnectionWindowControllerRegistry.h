//
// MUConnectionWindowControllerRegistry.h
//
// Copyright (c) 2013 3James Software.
//

#import "MUConnectionWindowController.h"
#import "MUProfile.h"

@interface MUConnectionWindowControllerRegistry : NSObject

@property (copy) NSMutableArray *connectionWindowControllers;

@property (readonly) NSUInteger connectedWorldCount;

+ (MUConnectionWindowControllerRegistry *) defaultRegistry;

@end
